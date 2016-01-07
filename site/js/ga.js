var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-39213747-2']);
_gaq.push(['_setDomainName', 'blog.lgohlke.de']);
_gaq.push(['_setSiteSpeedSampleRate', 100]);
_gaq.push(['_gat._forceSSL']);
_gaq.push(['_gat._anonymizeIp']);
_gaq.push(['_trackPageview']);

window.onerror = function (message, file, line) {
    _gaq.push(['_trackEvent', 'JS Error', file + ':' + line + '\n\n' + message]);
};

(function () {
    var ga = document.createElement('script');
    ga.type = 'text/javascript';
    ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0];
    s.parentNode.insertBefore(ga, s);
})();
