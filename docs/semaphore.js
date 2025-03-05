let observer = new MutationObserver(mutations => {
    let messageLabel = document.querySelectorAll("label")
    messageLabel.forEach(elem => {
        if (elem.textContent.includes("Message (Optional)")) {
            elem.parentElement.parentElement.parentElement.parentElement.remove();
        }
    });
    let forkIcons = document.querySelectorAll('.mdi-source-fork');
    forkIcons.forEach(icon => {
        if (icon.parentNode && icon.parentNode.tagName === 'SPAN') {
            icon.parentNode.hidden = true;
        }
    });
});
observer.observe(document, {childList: true, subtree: true});