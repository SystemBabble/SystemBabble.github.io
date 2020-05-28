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

### Configuration

There are 2 main configuration files to worry about.

[/etc/config/network](./files/etc/config/network)

This file defines the network interface configuration.
Define ip addresses, vlans, routes and switch configuration here.

##### Interfaces

In the example file there are 3 vlan interfaces

vlan2 the 'administrative' vlan, this will carry radius traffic and other
protocols such as ntp and ssh, and serve as the default route vlan.

```
# administrative vlan
config interface 'vlan2'
        option type 'bridge'
        option ifname 'eth0.2'
        option proto 'static'
        option ipaddr '10.1.2.2'
        option netmask '255.255.255.0'
        option stp '1'
        option igmp_snooping '1'

# default route to admin vlan
config 'route'
        option 'interface' 'vlan2'
        option 'target' '0.0.0.0'
        option 'netmask' '0.0.0.0'
        option 'gateway' '10.1.2.1'
        option 'metric' 0

```

vlan3 the 'default' vlan, this vlan will be assigned to clients that pass
EAP authentication but do not get assigned another vlan. Note: the *server*
not the *authenticator* will assign the supplicant the default vlan.

```
config interface 'vlan3'
        option type 'bridge'
        option ifname 'eth0.3'
        option proto 'static'
        option ipaddr '10.1.3.2'
        option netmask '255.255.255.0'
        option stp '1'
        option igmp_snooping '1'
```

vlan4 and so on would be assigned to clients by the radius server response.

```
config interface 'vlan4'
        option type 'bridge'
        option ifname 'eth0.4'
        option proto 'static'
        option ipaddr '10.1.4.2'
        option netmask '255.255.255.248'
        option stp '1'
        option igmp_snooping '1'
```

##### Switch configuration 

Enable vlans

```
config switch
        option name 'switch0'
        option reset '1'
        option enable_vlan '1'

```

For each vlan, decide which ports are tagged and untagged.

```
config switch_vlan
        option device 'switch0'
        option vlan '2'
        option ports '1t 2t 3 4t 0t'

config switch_vlan
        option device 'switch0'
        option vlan '3'
        option ports '1t 4t 0t'
```



[/etc/config/wireless](./files/etc/config/wireless)





*Note about ssh*

Dropbear has an odd bug on MIPS16 where it hangs when you try and ssh into a
device. Just Ctrl+C and try 4 times and it will work on the 3rd or 4th attempt.

[https://dev.archive.openwrt.org/ticket/15209]([https://dev.archive.openwrt.org/ticket/15209])
[https://forum.archive.openwrt.org/viewtopic.php?id=70368&p=1#p355173](https://forum.archive.openwrt.org/viewtopic.php?id=70368&p=1#p355173)


