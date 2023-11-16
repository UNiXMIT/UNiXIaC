// ==UserScript==
// @name        AnsibleSemaphore
// @namespace   https://www.ansible-semaphore.com/
// @match       https://domain.com/*
// @grant       none
// @version     1.0
// @author      MTurner
// @description Enhance Ansible Semaphore Username and Password fields.
// ==/UserScript==

let observer = new MutationObserver(mutations => {
	for (const elem of document.querySelectorAll("label")) {
		if (elem.textContent.includes("Message (Optional)")) {
		  elem.parentElement.parentElement.parentElement.parentElement.remove();
		}
	  }
	  for (const elem of document.querySelectorAll("label")) {
		if (elem.textContent.includes("SSO Email")) {
		  elem.nextSibling.type = 'email';
		}
	  }
	  for (const elem of document.querySelectorAll("label")) {
		if (elem.textContent.includes("SSO Password")) {
		  elem.nextSibling.type = 'password';
		}
	  }
  });
  observer.observe(document, {childList: true, subtree: true});