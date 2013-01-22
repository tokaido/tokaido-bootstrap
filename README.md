# Tokaido::Bootstrap

Tokaido Bootstrap is the entry point for the Tokaido GUI. It also
provides the initial installation.

## Bootstrap (bin/tokaido-bootstrap)

Make sure to set `$TOKAIDO_TMPDIR`

1. Boot tokaido-dns
2. Boot muxr
3. Listen on `$TOKAIDO_TMPDIR/muxr.sock` for apps to add or remove
4. Publish logs on `$TOKAIDO_TMPDIR/log.sock`
5. Enable the firewall rules

## Shutdown

1. Shut down `tokaido-dns`
2. Shut down `muxr`
3. Close `$TOKAIDO_TMPDIR/muxr.sock` and delete the file
4. Disable the firewall rules

## Muxr Protocol (`$TOKAIDO_TMPDIR/muxr.sock`)

The configuration protocol is a line protocol.

### Adding an Application

Adding an application will add it to muxr's proxy and boot it up.

```
ADD "<directory>" "<host>" port
```

Subsequent messages about this application will use the host as an
identifier.

If the directory, host and port are all available, you will receive an
immediate acknowledgement.

```
ADDED "<host>"
```

Once the application has finished booting and is ready to receive
requests, tokaido-bootstrap will send:

```
READY "<host>"
```

If the request was in an invalid format, tokaido-bootstrap will send:

```
INVALID
```

If an application could not be booted or did not publish the expected
port, tokaido-bootstrap will send:

```
ERR "<host>" no-boot
```

If a host did not end with the correct domain (`.tokaido`),
tokaido-bootstrap will send:

```
ERR "<host>" invalid-host
```

If an application at that directory is already present,
tokaido-bootstrap will respond:

```
DUP "<host>" directory
```

If an application at that host is already present, tokaido-bootstrap
will respond:

```
DUP "<host>" host
```

If an application at that port is already present, tokaido-bootstrap
will respond:

```
DUP "<host>" port
```

If there are multiple duplicate entries, tokaido-bootstrap will respond
with a space-separated list of the duplicate entries:

```
DUP "<host>" directory host
```

If muxr is not managing an app at the requested port, and muxr cannot
bind to the port (i.e. the port is already used by the system),
tokaido-bootstrap will respond:

```
ERR "<host>" port
```

### Removing an Application

Removing an application will remove it from the muxr proxy and shut it
down.

```
REMOVE "<host>"
```

If all goes well, tokaido-bootstrap will respond:

```
REMOVED "<host>"
```

If the host could not be found, tokaido-bootstrap will respond:

```
MISSING "<host>"
```

## Logs ($TOKAIDO_RUBY_LOGGER)

The logger protocol is:

```
<service> <severity> <timestamp> <has-longdesc> "<shortdesc>"
<longdesc>
!~DONE~!
```

* **service** the name of the service that the log is for. Currently,
  the only options are `dns` or `proxy`
* **severity** the severity of the error. See below.
* **timestamp** a timestamp for the log entry. Can be parsed with
  `[NSDate dateWithString]` (`YYYY-MM-DD HH:MM:SS ±HHMM`)
* **has-longdesc** true if the log entry is followed by a long
  description (e.g. a backtrace)
* **shortdesc** a quote-escaped short description, suitable for
  presentation to the user if appropriate.
* **longdesc** a long description that does not contain the string
  `!~DONE~!`. Appropriate for presentation to the user if more
  information is requested. If sending information about errors to a
  Tokaido server, the long description should be included, as it may
  contain backtraces or other information.
* **!~DONE~!** The end of the long description.

In general, the Tokaido UI should take action based on the severity of
the log:

* `fatal`: tokaido-bootstrap has exited. Either restart
  tokaido-bootstrap or ask the user to restart Tokaido.
* `error`: something has gone wrong that was not part of the normal
  Tokaido IPC protocol. This may leave tokaido-bootstrap in an unstable
  state, and the only reliable recovery option is to restart
  tokaido-bootstrap. If the error comes from `tokaido-dns`, it means
  that a DNS query failed. You can probably safely ignore it until
  it happens frequently.
* `warning`: something problematic occurred that would probably be
  useful in identifying a problem. Errors of this severity or higher
  might be useful to present to a user in a "debugging" screen.
* `info`: general informative information, such as booting, shutting
  down, etc.
* `debug`: verbose information, such as handling each request. In
  general, logs at this level are only useful for Tokaido developers
  tracking down bugs. It should be sent with crash logs, etc.

## Installation

On first boot of the Tokaido UI, `tokaido-bootstrap` provides a Ruby
script (`bin/tokaido-install`) that should be run with root privileges
(e.g. using SMJobSubmit).

It performs the following tasks:

* Installs a LaunchDaemon that allows the firewall rules to be enabled
  and disabled
* If necessary, adds an Apache config to listen on port 8080

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
