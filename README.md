obsd-minecraft
==============

Running the Minecraft client natively on OpenBSD.

THIS WRITEUP WORKS FOR ME BUT IS STILL BEING TESTED. YMMV.

This write up has been tested on a freshly installed OpenBSD-current amd64
snapshot from 2014-02-21 with no packages installed except those listed below
and their dependencies that are automatically pulled in by pkg_add.  This has
NOT been tested on i386.

####Intro

I have been trying to get Minecraft working on OpenBSD for quite some time.  My
kids and I enjoy playing the game together and so I wanted it to work on my
OpenBSD laptop.  In order to do so, however, I needed to build the Lightweight
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

UPDATE 2014-09-29: qbit submitted some patches upstream to LWJGL to get it to
build natively on OpenBSD and the patches were just accepted, which is awesome!
I have not tried the patches yet but they look like they should work fine.
Check them out here: https://github.com/LWJGL/lwjgl/pull/54

UPDATE #2 2014-09-29: qbit has now created a port and submitted it to ports@
for review, which is even more awesome.  Thanks @qbit!  Hopefully the port will
make its way into the OpenBSD ports tree and eventually a package will be
created which will eliminate the need for most of this writeup.  The only thing
that might be needed is the startup script, properly tweaked.  I'll test out
his port and then modify this writeup accordingly.  Link to the submitted port:
http://marc.info/?l=openbsd-ports&m=141202539713097&w=2

UPDATE #3 2014-09-30: qbit's port has been imported to the OpenBSD ports tree.  \o/ - this means this whole writeup will be unnecessary once everyone can use the port or the package.  I will update this README to bring it up to date with the last patch but overall this writeup is now deprecated other than the starter helper script. :-)  Big thanks to dc740 and qbit!
####Preliminary step

First, a preliminary step common to running java apps on OpenBSD -- the ulimit
datasize.  I won't go into detail here (just Google it for more information)
but check the output of your regular user's ulimit -d size.  If it's at 512M,
then you might need to edit /etc/login.conf and change the 'staff' datasize-cur
to 1024M or 2048M, otherwise the Minecraft.jar file won't run.  See man
login.conf.

####The 9 easy steps

Step 1. As root, install these necessary packages:

   * audio/openal (to build lwjgl and for the game)
   * devel/jdk-1.7.0 (to build lwjgl and for the game)
   * java/apache-ant (to build lwjgl)

Step 2. As your regular user, add /usr/local/jdk-1.7.0/bin to your $PATH if you
haven't already done so in your $HOME/.profile or similar.  This is needed to
pull in the java and apache-ant binaries (e.g. apt) to build lwjgl and also
makes it easier to launch Minecraft.jar since 'java' will be in your $PATH.

```
    $ export PATH=${PATH}:/usr/local/jdk-1.7.0/bin
```

Step 3. Create a workdir and cd into it.

```
    $ mkdir $HOME/workdir ; cd $HOME/workdir
```

Step 4. Download the lwjgl2.9.1.tar.gz source from Github and save it to the
workdir you created in Step 3 and then extract the tarball:

```
    $ ftp https://github.com/LWJGL/lwjgl/archive/lwjgl2.9.1.tar.gz
    $ tar -zxvf lwjgl2.9.1.tar.gz
    $ cd lwjgl-lwjgl2.9.1
```

Step 5. Grab the three patches found here in this git repo that will help us
buile lwjgl natively on OpenBSD and then apply them to build.xml and
platform_build/bsd_ant/build.xml and src/native/linux/opengl/extgl_glx.c.

```
    $ ftp https://raw.github.com/chessgriffin/obsd-minecraft/master/patch-build_xml
    $ ftp https://raw.github.com/chessgriffin/obsd-minecraft/master/patch-platform_build_bsd_ant_build_xml
    $ ftp https://raw.github.com/chessgriffin/obsd-minecraft/master/patch-src_native_linux_opengl_extgl_glx_c
    $ patch build.xml < patch-build_xml
    $ patch platform_build/bsd_ant/build.xml < patch-platform_build_bsd_ant_build_xml
    $ patch src/native/linux/opengl/extgl_glx.c < patch-src_native_linux_opengl_extgl_glx_c
```

Step 6. Build lwjgl.

```
    $ ant
```

The compile should take less than three minutes on a reasonably modern machine.
The resulting libraries are:

   * libs/lwjgl.jar
   * libs/lwjgl_util.jar
   * libs/openbsd/liblwjgl64.so

Step 7. Grab the script called 'native-lwjgl.sh' from the git repo here and
save it somewhere in your user's $HOME and make it executable.

```
    $ ftp https://raw.github.com/chessgriffin/obsd-minecraft/master/native-lwjgl.sh
    $ chmod +x native-lwjgl.sh
```

Check the variables at the top of the script to see if you need to change
anything.  Basically, they are simply pointing to the directory where you built
lwjgl in your $HOME directory.  If you used the 'workdir' name suggested in
Step 3, then you probably don't need to edit the script at all but check it out
just in case.

Step 8. Launch the Minecraft.jar

```
    $ java -jar Minecraft.jar
```

Once you've logged in and the game downloads all the textures, sounds,
libraries etc., click "Edit Profile" and click the box labeled "Executable".
Enter the path to the 'native-lwjgl.sh' script from Step 7.  Then click "Save
Profile" and then "Play."

Step 9.  Enjoy playing Minecraft on OpenBSD.

Please let me know if this works or doesn't work or if you have any suggestions
on how to improve this writeup.  Thank you!

Attributions:

[1] http://devnull.sig11.fr/minecraft/HOWTO_MINECRAFT_ON_FREEBSD.txt

[2] http://forums.freebsd.org/viewtopic.php?f=5&t=42932
