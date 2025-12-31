// ================= CONFIG =================
const API_BASE = "https://i2pyjz4fm2.execute-api.us-east-1.amazonaws.com/dev";

const ENDPOINTS = {
  presign: "/presign-upload",
  verify: "/verify"
};

// ================= STATE =================
let stream = null;

// ================= DOM =================
const el = (id) => document.getElementById(id);

const useCameraBtn = el("useCameraBtn");
const useUploadBtn = el("useUploadBtn");

const cameraSection = el("cameraSection");
const uploadSection = el("uploadSection");

const videoEl = el("video");
const fileInputEl = el("fileInput");

const startCameraBtn = el("startCameraBtn");
const captureBtn = el("captureBtn");
const stopCameraBtn = el("stopCameraBtn");
const verifyUploadBtn = el("verifyUploadBtn");

const statusPill = el("statusPill");
const statusText = el("statusText");

const banner = el("banner");
const bannerTitle = el("bannerTitle");
const bannerSubtitle = el("bannerSubtitle");

const previewImg = el("previewImg");

// ================= UI HELPERS =================
function setPill(kind, text) {
  statusPill.className = `pill ${kind}`;
  statusPill.textContent = text;
}

function setStatus(text) {
  statusText.textContent = text;
}

function showBanner(kind, title, subtitle = "") {
  banner.className = `banner ${kind}`;
  bannerTitle.textContent = title;
  bannerSubtitle.textContent = subtitle;
  banner.classList.remove("hidden");
}

function hideBanner() {
  banner.classList.add("hidden");
}

function setPreviewFromBlob(blob) {
  previewImg.src = URL.createObjectURL(blob);
  previewImg.classList.remove("hidden");
}

// ================= CAMERA =================
async function startCamera() {
  if (stream) return;

  stream = await navigator.mediaDevices.getUserMedia({ video: true });
  videoEl.srcObject = stream;

  setPill("idle", "Ready");
  setStatus("Camera started");
}

function stopCamera() {
  if (!stream) return;

  stream.getTracks().forEach((t) => t.stop());
  stream = null;
  videoEl.srcObject = null;

  setPill("idle", "Idle");
  setStatus("Camera stopped");
}

function captureFrameToBlob() {
  const canvas = document.createElement("canvas");
  canvas.width = videoEl.videoWidth || 1280;
  canvas.height = videoEl.videoHeight || 720;

  canvas.getContext("2d").drawImage(videoEl, 0, 0);
  return new Promise((resolve) =>
    canvas.toBlob(resolve, "image/jpeg", 0.92)
  );
}

// ================= API =================
async function apiPost(path, payload) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });

  if (!res.ok) {
    throw new Error("Request failed");
  }

  return res.json();
}

async function uploadToS3(uploadUrl, blob, contentType) {
  const res = await fetch(uploadUrl, {
    method: "PUT",
    headers: { "Content-Type": contentType },
    body: blob
  });

  if (!res.ok) {
    throw new Error("Upload failed");
  }
}

// ================= FLOW =================
function makeGateObjectKey() {
  return `gate/capture-${crypto.randomUUID()}.jpg`;
}

async function verifyBlob(blob, contentType) {
  hideBanner();
  setPill("idle", "Working");
  setStatus("Uploading image");

  const objectKey = makeGateObjectKey();

  const presign = await apiPost(ENDPOINTS.presign, {
    objectKey,
    contentType
  });

  await uploadToS3(presign.uploadUrl, blob, contentType);

  setStatus("Verifying identity");

  const result = await apiPost(ENDPOINTS.verify, { objectKey });

  if (result.isMatch) {
    setPill("good", "Granted");
    showBanner("good", "Access Granted");
  } else {
    setPill("bad", "Denied");
    showBanner("bad", "Access Denied");
  }

  setStatus("Verification complete");
}

// ================= EVENTS =================
verifyUploadBtn.onclick = async () => {
  try {
    const file = fileInputEl.files[0];
    if (!file) return;

    setPreviewFromBlob(file);
    await verifyBlob(file, file.type);

  } catch {
    setPill("bad", "Error");
    showBanner("bad", "Access Denied");
  }
};

captureBtn.onclick = async () => {
  try {
    const blob = await captureFrameToBlob();
    setPreviewFromBlob(blob);
    await verifyBlob(blob, "image/jpeg");

  } catch {
    setPill("bad", "Error");
    showBanner("bad", "Access Denied");
  }
};

startCameraBtn.onclick = startCamera;
stopCameraBtn.onclick = stopCamera;

// ================= INIT =================
function init() {
  setPill("idle", "Idle");
  setStatus("Ready");
  hideBanner();
}

init();
