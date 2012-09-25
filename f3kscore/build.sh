#!/bin/bash

f3kscore_zip=F3KScore_v8.9.zip
f3kscore_patched_zip=F3KScore_v8.9_patched.zip
f3kscore_url=http://olgol.com/F3KScore/$f3kscore_zip
f3kscore_jar=f3kscore_v8.9.jar

if [ ! -f $f3kscore_zip ]; then
    curl $f3kscore_url -o $f3kscore_zip
fi

cp $f3kscore_zip $f3kscore_patched_zip

unzip -o $f3kscore_patched_zip $f3kscore_jar -d lib
classpath=""
for jar in ./lib/*.jar; do
    classpath="$classpath:$jar"
done

javac -cp $classpath f3kscore/XmlSaver.java

mkdir .build
unzip -o lib/$f3kscore_jar -d .build
perl -pi -e 's/Main-Class: f3kscore\/F3KScore/Main-Class: f3kscore\/XmlSaver/' .build/META-INF/MANIFEST.MF
perl -pi -e 's/Class-Path:/Class-Path: lib\/xmlpull-1.1.3.1.jar lib\/xstream-1.4.2.jar/' .build/META-INF/MANIFEST.MF
( cd .build; zip ../lib/$f3kscore_jar META-INF/MANIFEST.MF )
zip lib/$f3kscore_jar f3kscore/XmlSaver*.class

zip $f3kscore_patched_zip -j lib/$f3kscore_jar
zip $f3kscore_patched_zip lib/xmlpull-1.1.3.1.jar
zip $f3kscore_patched_zip lib/xstream-1.4.2.jar

rm -rf .build
rm -f lib/$f3kscore_jar

echo "Done..." 
