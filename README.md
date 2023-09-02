# Setup for Computer Science FTP at CRICS

* Repo additions: `README.md _pure-ftpd.conf purecsv lspdb.v lspdb.c lspdb`
  - `README.md`: Instructions for install and usage.
  - `_pure-ftpd.conf`: Configuration for Virtual Users.
  - `purecsv`: Setup virtual accounts and mail out details.
* **There is also a `.deb` package `pure-ftpd`, but it's default locations are different!**
* Files that will be added on the user side: `.netrc` and `pure.csv`

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

## Have an A record for the URL in the DNS server for the domain

## Setup and run `caddy`
* In `Caddyfile`:
```
URL {
	root * /home/pureftp
	redir / SOMEWEBPAGE
	file_server
}
```
* Start `caddy` when in the directory with the `Caddyfile`: `caddy start`

## Symlink the domain certificate to /etc/ssl/private/pure-ftpd.pem (replace URL)
`ln -sf /root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/URL/URL.crt /etc/ssl/private/pure-ftpd.pem`

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
* Have 1 line with the bare URL (no scheme), like: `machine URL`
* Have 1 line with the SMTP login email, like: `login EMAIL`
* Have 1 line with the SMTP password, like: `password PASSWORD`

### Add/modify users with `pure.csv` file with lines: <section>,<username>
`./purecsv`

* If the line is prepended by `#` it is ignored.
* If the line is prepended by `*` the login covers the whole section and all users in it.
* If the line has `*` as its section, it designates the superuser `pureftp` over all sections.
* Usernames have to be unique! (Otherwise the last one wins.)

### Users can also be edited directly
`sudo nano /etc/pureftpd.passwd`

### Commit changes = make database (no restart needed)
`sudo pure-pw mkdb`

### Add one teacher
```
sudo pure-pw useradd <username> -u pureftp -g pureftp -d /home/pureftp/<section>
# With flag `-m` the live database will get updated without doing `pure-pw mkdb`.
```

### Add one user
```
sudo pure-pw useradd <username> -u pureftp -g pureftp -d /home/pureftp/<section>/<username>
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
