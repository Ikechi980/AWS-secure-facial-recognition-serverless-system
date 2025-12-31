// ================= CONFIG =================
const COGNITO_DOMAIN =
  "https://ike-facial-recognition-app.auth.us-east-1.amazoncognito.com";

const CLIENT_ID = "5c60ft5ni9afnsf4eu0pbveqbb";

const REDIRECT_URI = window.location.origin + "/admin/";

const API_BASE =
  "https://flc7vqnomd.execute-api.us-east-1.amazonaws.com/dev";

// ================= AUTH =================
function login() {
  const url =
    `${COGNITO_DOMAIN}/login?` +
    `client_id=${CLIENT_ID}` +
    `&response_type=code` +
    `&scope=openid+email+profile` +
    `&redirect_uri=${encodeURIComponent(REDIRECT_URI)}`;

  window.location.href = url;
}

function logout() {
  const url =
    `${COGNITO_DOMAIN}/logout?` +
    `client_id=${CLIENT_ID}` +
    `&logout_uri=${encodeURIComponent(REDIRECT_URI)}`;

  localStorage.clear();
  window.location.href = url;
}

// ================= TOKEN =================
async function exchangeCode(code) {
  const body = new URLSearchParams({
    grant_type: "authorization_code",
    client_id: CLIENT_ID,
    code,
    redirect_uri: REDIRECT_URI
  });

  const res = await fetch(`${COGNITO_DOMAIN}/oauth2/token`, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded"
    },
    body
  });

  if (!res.ok) {
    throw new Error("Token exchange failed");
  }

  const data = await res.json();

  // ✅ API Gateway Cognito Authorizer requires ID TOKEN
  localStorage.setItem("id_token", data.id_token);
}

function getToken() {
  return localStorage.getItem("id_token");
}

// ================= API =================
async function apiPost(path, payload) {
  const token = getToken();
  if (!token) {
    throw new Error("Not authenticated");
  }

  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: {
      // ✅ REQUIRED FORMAT
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(payload)
  });

  const data = await res.json();
  if (!res.ok) {
    throw new Error(JSON.stringify(data));
  }

  return data;
}

// ================= S3 UPLOAD =================
async function uploadImage(file, employeeId) {
  const objectKey = `enroll/${employeeId}/reference.jpg`;

  // 1️⃣ Request presigned URL
  const presign = await apiPost("/presign-upload", {
    objectKey,
    contentType: file.type
  });

  // 2️⃣ Upload directly to S3
  const upload = await fetch(presign.uploadUrl, {
    method: "PUT",
    headers: {
      "Content-Type": file.type
    },
    body: file
  });

  if (!upload.ok) {
    throw new Error("S3 upload failed");
  }

  return objectKey;
}

// ================= ENROLL =================
async function enrollEmployee() {
  const employeeId =
    document.getElementById("employeeId").value.trim();

  const file =
    document.getElementById("fileInput").files[0];

  if (!employeeId || !file) {
    alert("Employee ID and image required");
    return;
  }

  try {
    setStatus("Uploading image to S3");

    const objectKey =
      await uploadImage(file, employeeId);

    setStatus("Enrolling face with Rekognition");

    const result = await apiPost("/enroll", {
      employeeId,
      objectKey
    });

    setStatus("Enrollment successful");
    showResult(result);

  } catch (err) {
    setStatus("Enrollment failed");
    showResult({ error: err.message });
  }
}

// ================= UI =================
function setStatus(text) {
  document.getElementById("status").textContent = text;
}

function showResult(data) {
  document.getElementById("result").textContent =
    JSON.stringify(data, null, 2);
}

// ================= INIT =================
function init() {
  const params = new URLSearchParams(window.location.search);
  const code = params.get("code");

  if (code) {
    exchangeCode(code)
      .then(() => {
        window.history.replaceState(
          {},
          document.title,
          "/admin/"
        );
        setStatus("Signed in");
      })
      .catch(() => {
        setStatus("Login failed");
      });

  } else if (getToken()) {
    setStatus("Signed in");

  } else {
    setStatus("Not signed in");
  }

  document.getElementById("loginBtn").onclick = login;
  document.getElementById("logoutBtn").onclick = logout;
  document.getElementById("enrollBtn").onclick = enrollEmployee;
}

init();
