var exec = require('cordova/exec');

exports.speak = function (text, language, success, error) {
    exec(success, error, 'OSSpeech', 'speak', [text,language]);
};

exports.listen = function (language, success, error) {
    exec(success, error, 'OSSpeech', 'listen', [language]);
};