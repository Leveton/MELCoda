var styleTag = document.createElement("style");
//styleTag.textContent = 'div#sidebar, .after-post.widget-area {display:none;}';
styleTag.textContent = 'div#sidebar, .footer-widgets {display:none;}';
document.documentElement.appendChild(styleTag);