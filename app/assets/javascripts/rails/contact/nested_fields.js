(() => {
  function addRow(event) {
    const button = event.target.closest("[data-add-nested]");
    if (!button) return;

    const wrapper = button.closest("[data-nested-wrapper]");
    const targetSelector = button.dataset.target;
    const templateSelector = button.dataset.template;
    if (!wrapper || !targetSelector || !templateSelector) return;

    const container = wrapper.querySelector(targetSelector);
    const template = wrapper.querySelector(templateSelector);
    if (!container || !template) return;

    const uniqueId = String(Date.now() + Math.floor(Math.random() * 1000));
    const html = template.innerHTML.replace(/NEW_RECORD/g, uniqueId);
    container.insertAdjacentHTML("beforeend", html);
  }

  function removeRow(event) {
    const button = event.target.closest("[data-action='nested-fields#remove']");
    if (!button) return;
    const row = button.closest("[data-nested-fields-target='row']");
    if (!row) return;

    const destroyField = row.querySelector("[data-nested-fields-target='destroyField']");
    if (destroyField) {
      destroyField.value = "1";
      row.style.display = "none";
    } else {
      row.remove();
    }
  }

  document.addEventListener("click", (event) => {
    if (event.target.closest("[data-add-nested]")) {
      event.preventDefault();
      addRow(event);
      return;
    }
    if (event.target.closest("[data-action='nested-fields#remove']")) {
      event.preventDefault();
      removeRow(event);
    }
  });
})();
