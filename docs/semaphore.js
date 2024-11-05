let observer = new MutationObserver(mutations => {
    for (const elem of document.querySelectorAll("label")) {
        if (elem.textContent.includes("Message (Optional)")) {
          elem.parentElement.parentElement.parentElement.parentElement.remove();
        }
      }
  });
observer.observe(document, {childList: true, subtree: true});