# Batch setup for Virtual Users over a directory and email the details

* Repo additions: `README.md _pure-ftpd.conf purecsv lspdb.v lspdb.zig lspdb.c lspdb`
  - `README.md`: Instructions for install and usage.
  - `_pure-ftpd.conf`: Ready-made configuration for Virtual Users.
  - `purecsv`: Setup virtual accounts and mail out details.
  - `lspdb.v`, `lspdb.zig` and `lspdb.c`: Sources for `lspdb`.
  - `lspdb`: Binary to list all entries in a PureDB database like `/etc/pureftpd.pdb`.
* Files that need to be added by the user for deployment: `.netrc` and `pure.csv`
* **There is also a `.deb` package `pure-ftpd`, but its default locations are different!**

## Prep for building
```
apt install automake libssl-dev
git clone https://github.com/pepa65/pure-ftpd
cd pure-ftpd
```

## Building (with Virtual Users, Encrypted file transfer, and pure-ftpwho)
```
./autogen.sh 
./configure --with-puredb --with-tls --with-ftpwho
cp _pure-ftpd.conf pure-ftpd.conf
sudo make install-strip
```

## Have an A record for the DOMAIN in the DNS server for the domainroot

## Setup and run `caddy (v2)`
* Add to `Caddyfile`:
```
DOMAIN {
	root * /home/pureftp
	redir / https://SOMEWEBPAGE
	file_server
}
```
* Start `caddy` when in the directory with the `Caddyfile` by: `caddy start`

## Symlink the domain certificate to /etc/ssl/private/pure-ftpd.pem (replace DOMAIN)
`sudo ln -sf ~/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/DOMAIN/DOMAIN.crt /etc/ssl/private/pure-ftpd.pem`

## Prep for the owner of the virtual users
```
sudo groupadd pureftp
sudo useradd -g pureftp -d /dev/null -s /bin/false pureftp
```

## Manage `pure-ftpd`

### Start (chroot everyone, daemonize, list dotfiles, only auth-users, no whois, make home, PureDB-auth)
```
sudo /usr/local/sbin/pure-ftpd -A -B -D -E -H -j -lpuredb:/etc/pureftpd.pdb
# Add this to /root/atreboot, perhaps with `pkill -x pure-ftpd` before it
```

### Stop
`sudo pkill -x pure-ftpd`

## Manage Virtual Users

### Prep `.netrc` which is used in `purecsv`
* Needed if details need to be emailed out (alternative: output passwords to stdout)
* Have 1 line with the bare DOMAIN (no scheme), like: `machine DOMAIN`
* Have 1 line with the SMTP login user, like: `login USERNAME`
* Have 1 line with the SMTP password, like: `password PASSWORD`

### Add/modify users with `pure.csv` file with lines: <directory>,<username>,<email>
`./purecsv`

* If the line is prepended by `#` it is ignored as a comment.
* `<dir>` is the directory that user `<username>` has authorization for. Examples:
  - `/`: Covering all subdirectories (superadmin).
  - `/cs7`: User with authorization over everything under `/cs7` (teacher).
  - `/cs9/int`: User with authorization over `/cs9/int` (student).
* Every `<username>` has to be unique! (Otherwise the last one wins.)
* If `<email>` is filled in, an email is sent with the details for the virtual user.
  Otherwise, the password will be printed to stdout.

### Users can also be edited directly
`sudo nano /etc/pureftpd.passwd`

### Commit changes = make database (no restart needed)
`sudo pure-pw mkdb`

### Add a user
```
sudo pure-pw useradd <username> -u pureftp -g pureftp -d /home/pureftp/<dir>
# With flag `-m` the live database will get updated without doing `pure-pw mkdb`.
```

### Change/reset user password (also updates the live database)
`sudo pure-pw passwd <username> -m`

### See who is active
`sudo pure-ftpwho`

### List contents of live database
`sudo lspdb /etc/pureftpd.pdb`

### Restoring text database from running database
`sudo lspdb /etc/pureftpd.pdb >/etc/pureftpd.passwd`
