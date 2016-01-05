ifeq ($(origin JAVA_HOME), undefined)
  JAVA_HOME=/usr
endif

ifeq ($(origin NETLOGO), undefined)
  NETLOGO=../..
endif

ifneq (,$(findstring CYGWIN,$(shell uname -s)))
  COLON=\;
  JAVA_HOME := `cygpath -up "$(JAVA_HOME)"`
else
  COLON=:
endif


SRCS=$(wildcard src/org/nlogo/extensions/ahninn/*.java)

dist: ahninn.jar ahninn.zip
	cp -a ahninn ../models/
	
ahninn.jar: $(SRCS) ahni.jar manifest.txt
	mkdir -p classes
	$(JAVA_HOME)/bin/javac -g -encoding us-ascii -source 1.6 -target 1.6 -classpath $(NETLOGO)/NetLogoLite.jar$(COLON)ahni.jar -d classes $(SRCS)
	jar cmf manifest.txt ahninn.jar -C classes .

ahninn.zip: ahninn.jar
	rm -rf ahninn
	mkdir ahninn
	cp -rp ahninn.jar ahni.jar README.md Makefile src manifest.txt ahninn
	zip -rv ahninn.zip ahninn *.nlogo*
	#rm -rf ahninn

