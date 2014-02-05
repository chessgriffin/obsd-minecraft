obsd-minecraft
==============

Running the Minecraft client natively on OpenBSD.

THIS WRITEUP IS STILL BEING TESTED. YMMV.

This write up has been tested on a freshly installed OpenBSD-current amd64
snapshot from 2014-02-03 with no packages installed except those listed below
and their dependencies that are automatically pulled in by pkg_add.  This has
NOT been tested on i386.

#### Intro

I have been trying to get Minecraft working on OpenBSD for quite some time.  My
kids and I enjoy playing the game together and so I wanted it to work on my
OpenBSD laptop.  In order to do, however, I needed to build the Lightweight
Java Game Library (http://lwjgl.org) run-time dependency natively on the
system.  It appeared that lwjgl required two other libraries in order to build:
jinput and jutils.  I found a guide written for FreeBSD [1] that got me started
although it was deprecated once Minecraft and its related libraries were added
to the FreeBSD ports tree.  I tried various ways of building and compiling the
three libraries without much success.

However, I found a source tarball on lwjgl's Github repository that seemed to
build without jinput or jutils.  I also found a post in the FreeBSD forums [2]
in which the user amracks posted a script that helped me get Minecraft 1.7.4
working on FreeBSD (the ports version is stuck back at the 1.4.x version of
Minecraft before Mojang changed the launcher).  I figured if it works on
FreeBSD there must be a way to get it working on OpenBSD. :-)

So here is my little writeup with a couple of patches and a script that got
Minecraft running natively on OpenBSD.  This assumes you have a working OpenBSD
system, you've configured your $PKG_PATH to pull packages from the mirrors, and
you've got a copy of the Minecraft.jar file.

#### Preliminary step

First, a preliminary step common to running java apps on OpenBSD -- the ulimit
datasize.  I won't go into detail here (just Google it for more information)
but check the output of your regular user's ulimit -d size.  If it's at 512M,
then you might need to edit /etc/login.conf and change the 'staff' datasize-cur
to 1024M or 2048M, otherwise the Minecraft.jar file won't run.  See man
login.conf.

#### Warning

STUPID SYMLINK HACK LIES AHEAD IN STEP 8. I know, I know.  I am not smart
enough to figure out another way to get Minecraft.jar to find the libGL in
/usr/X11R6/lib so if you have a better way, please let me know so I can get rid
of the symlink. 

#### The 10 easy steps

1. As root, install these necessary packages:

   * audio/openal (for the game)
   * devel/jdk-1.7.0 (to build lwjgl and for the game)
   * java/apache-ant (to build lwjgl)

2. As your regular user, add /usr/local/jdk-1.7.0/bin to your $PATH if you
haven't already done so in your $HOME/.profile or similar.  This is needed to
pull in the java and apache-ant binaries (e.g. apt) to build lwjgl and also
makes it easier to launch Minecraft.jar since 'java' will be in your $PATH.

...
    $ export PATH=${PATH}:/usr/local/jdk-1.7.0/bin
...

3. Create a workdir and cd into it.

    $ mkdir $HOME/workdir ; cd $HOME/workdir

4. Download the lwjgl2.9.1.tar.gz source from Github and save it to the
workdir you created in Step 3 and then extract the tarball:

    $ ftp https://github.com/LWJGL/lwjgl/archive/lwjgl2.9.1.tar.gz
    $ tar -zxvf lwjgl2.9.1.tar.gz
    $ cd lwjgl-lwjgl2.9.1

5. Grab the two patches found here in this git repo that will help us build
lwjgl natively on OpenBSD and then apply them to build.xml and
platform_build/bsd_ant/build.xml.

    $ ftp https://raw.github.com/chessgriffin/obsd-minecraft/master/patch-build_xml
    $ ftp https://raw.github.com/chessgriffin/obsd-minecraft/master/patch-platform_build_bsd_ant_build_xml
    $ patch build.xml < patch-build_xml
    $ patch platform_build/bsd_ant/build.xml < patch-platform_build_bsd_ant_build_xml

6. Build lwjgl.

    $ ant

The compile should take less than three minutes on a reasonably modern machine.
The resulting libraries are:

    libs/lwjgl.jar
    libs/lwjgl_util.jar
    libs/openbsd/liblwjgl64.so

7. Grab the script called 'native-lwjgl.sh' from the git repo here and save it
somewhere in your user's $HOME and make it executable.

    $ ftp https://raw.github.com/chessgriffin/obsd-minecraft/master/native-lwjgl.sh
    $ chmod +x native-lwjgl.sh

8. STUPID HACK - link /usr/X11R6/lib/libGL.so.15.0 to /usr/local/lib/libGL.so.1
because otherwise the game won't run.  I tried adding the path /usr/X11R6/lib
to the -Djava.library.path variable in the native-lwjgl.sh script but it does
not seem to work.  Please let me know if you know how to properly address this
issue so I can get rid of this stupid symlink.

    (su to root or use sudo)
    # ln -sf /usr/X11R6/lib/libGL.so.15.0 /usr/local/lib/libGL.so.1
    (change back to regular user)

9. Launch the Minecraft.jar

    $ java -jar Minecraft.jar

Once you've logged in and the game downloads all the textures, sounds,
libraries etc., click "Edit Profile" and click the box labeled "Executable".
Enter the path to the 'native-lwjgl.sh' script from Step 7.  Then click "Save
Profile" and then "Play."

10.  Enjoy playing Minecraft on OpenBSD.

Attributions:
[1] http://devnull.sig11.fr/minecraft/HOWTO_MINECRAFT_ON_FREEBSD.txt
[2] http://forums.freebsd.org/viewtopic.php?f=5&t=42932
