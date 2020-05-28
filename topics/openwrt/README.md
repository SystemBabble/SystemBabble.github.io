# WPA2-802.1x/Enterprise Mode on OpenWrt tiny devices

## OpenWrt v18.06, 19.07

A while ago I wanted to get wireless enterprise authentication going. 
I have a dirt cheap ($15-20) TP-Link TL-WR841N v11 with support for 15 vlans.

wpad is a single package that provides the functionality of hostapd and
wpa_supplicant. wpad-mini is installed with OpenWrt by default for space saving
reasons, but either the full version of wpad, or hostapd is required for the
access point to act as an authenticator.

This article is going to focus on the AP that acts as an 802.1x authenticator.

![802.1x](https://upload.wikimedia.org/wikipedia/commons/1/17/802-1X.png)

Image by [Felix Bauer](https://commons.wikimedia.org/wiki/File:802-1X.png) / [CC BY-SA](https://creativecommons.org/licenses/by-sa/4.0)

See https://sysramble.github.io/topics/freeradius for FreeRADIUS configuration,
if you need an authentication server.

Because of space constraints on the TL-WR841N, there is no space for opkg to
install wpad. Building your own firmware image is required.

### Firmware

[https://openwrt.org/docs/guide-user/additional-software/saving_space](https://openwrt.org/docs/guide-user/additional-software/saving_space)

In short run `make menuconfig` remove the 
`ppp, iptables, odhcp, opkg, hostapd-mini` packages and add `wpad-openssl`

Don't add the LuCI GUI and instead use ssh to configure the device.

Prebuilt images for v19.07.02 are below.

* [OpenWrt v19.07.02](https://openwrt.org/releases/19.07/changelog-19.07.2)
* [tplink_tl-wr841-v11](https://openwrt.org/toh/hwdata/tp-link/tp-link_tl-wr841n_v11)
* [ath79-tiny target](https://openwrt.org/docs/techref/targets/ath79)
* No LuCi only Dropbear
* No iptables, ppp or opkg
* Full wpad-openssl

Use at your own risk: [bin/targets/ath79/tiny/](https://github.com/SystemBabble/SystemBabble.github.io/tree/master/topics/openwrt/files/tiny)


*Note about ssh*

[https://dev.archive.openwrt.org/ticket/15209]([https://dev.archive.openwrt.org/ticket/15209])
[https://forum.archive.openwrt.org/viewtopic.php?id=70368&p=1#p355173](https://forum.archive.openwrt.org/viewtopic.php?id=70368&p=1#p355173)

Dropbear has an odd bug on MIPS16 where it hangs when you try and ssh into a
device. Just Ctrl+C and try 4 times and it will work on the 3rd or 4th attempt.



