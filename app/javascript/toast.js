let current

// Shows one floating notification at a time. type: "split" | "crash" | "dividend"
export function showToast(type, html) {
  current?.remove()
  const toast = document.createElement("div")
  toast.className = `toast ${type}-toast`
  toast.innerHTML = html
  document.body.appendChild(toast)
  current = toast

  requestAnimationFrame(() => toast.classList.add("show"))
  setTimeout(() => {
    toast.classList.remove("show")
    setTimeout(() => toast.remove(), 300)
  }, 2500)
}
