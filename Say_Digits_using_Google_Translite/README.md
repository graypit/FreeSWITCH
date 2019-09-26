## In this README I'll show you how to use **Google-Translite-URL** in FreeSWITCH

#### Firstly you will install mod_shout:

```bash
$ apt freeswitch-mod-shout -y
```
#### Uncomment **mod_shout** in `/etc/freeswitch/autoload_configs/modules.conf.xml` and restart the FreeSWITCH
- Or you can load this module:
```bash
fs_cli -x 'load mod_shout'
```

#### Add the following lines to your dialplan XML:

```xml
<extension name="Google_Translate_Play_Digits">
  <condition field="destination_number" expression="^(2323)$">
	 <action application="answer"/>
	   <action application="sleep" data="300"/>
	   <action application="set" data="lang=en"/>
	   <action application="set" data="ivr=Hi...+To+translate+numbers+to+English+language+press+digits...+a+at+end+to+sharp..."/>
	   <action application="read" data="1 9 'shout://translate.google.com/translate_tts?ie=UTF-8&tl=${lang}&client=tw-ob&q=${ivr}' number 12000 #"/>
	   <action application="gentones" data="%(500,0,800)"/>
	   <action application="playback" data="shout://translate.google.com/translate_tts?ie=UTF-8&tl=${lang}&client=tw-ob&q=${number}"/>
     <action application="hangup"/>
  </condition>
</extension>
```

#### Call to 2323 via **SIP-Softphone** (e.g X-Lite or MicroSIP) and Enjoy !
