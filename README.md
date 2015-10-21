# exec-ccache

Simple [ccache](https://ccache.samba.org/) monitoring plugin for [collectd](https://collectd.org/). It requires [exec plugin](https://collectd.org/wiki/index.php/Plugin:Exec) enabled.

## Installation

1. If you want keep this plugin separated from collectd installation, to keep your system clean, I recommend putting exec-ccache.db and exec.ccache.sh in /usr/local/share/collectd
Otherwise you can install exec-ccache.sh file in any directory readable by collectd, and put contents of exec-ccache.db into main types.db from collectd installation.
2. Edit /etc/collectd.conf in order to add following entries:

```
# Add this, to keep types definition separate from collectd defaults
TypesDB     "/usr/local/share/collectd/exec-ccache.db"

[...]
# This is a must
LoadPlugin exec
[...]

# Exec plugin
<Plugin exec>
    Exec bmci "/usr/local/share/collectd/exec-ccache.sh"
</Plugin>
```

Above configuration covers basic usage - monitors ccache with 60 seconds interval and checks ccache of user who runs collectd

## Parameters

Exec plugin with --help to get usage information. You can change default user, interaval and hostname, otherwise these are taken from collectd defaults.
