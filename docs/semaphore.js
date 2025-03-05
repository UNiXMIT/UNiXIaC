let observer = new MutationObserver(mutations => {
    for (const elem of document.querySelectorAll("label")) {
        if (elem.textContent.includes("Message (Optional)")) {
          elem.parentElement.parentElement.parentElement.parentElement.remove();
        }
      }
    let forkIcons = document.querySelectorAll('.mdi-source-fork');
    forkIcons.forEach(icon => {
      const parentSpan = icon.closest('span');
      if (parentSpan) {
        parentSpan.style.display = 'hidden';
      }
    });
});
observer.observe(document, {childList: true, subtree: true});