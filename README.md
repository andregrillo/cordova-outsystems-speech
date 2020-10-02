# cordova-outsystems-speech
Plugin for using ios Speech recognition and Speech Synthesis

## Plugin calls

### Speech recognition
You should specify the language parameter and call this method two times, one for start recording the user's voice, and another time to stop it.
As soon as it stops recording, the audio will be sent to the iOS speech recognition api and it will return the spoken sentence as a text.
```
cordova.plugins.speech.listen("pt-PT", function(success){console.log("sucess: " + success)},function(error){console.log("Error: " + error)});
```

### Speech Synthesis
Provide the sentence to be read and the language as parameters:
```
cordova.plugins.speech.speak("Hey, I am back!", "en-US", function(success){},function(error){});
```
