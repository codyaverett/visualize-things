# Ansible Deployment

This directory contains Ansible playbooks for deploying visualize-things to the starbase server.

## Prerequisites

1. **Ansible installed**:
   ```bash
   brew install ansible
   ```

2. **SSH access to starbase**:
   - Ensure you can SSH to starbase without password (SSH keys configured)
   - Your user should have sudo privileges on starbase

3. **Nginx running on starbase**:
   - Nginx should be installed and running
   - Default nginx html directory: `/usr/share/nginx/html`

## Directory Structure

```
ansible/
├── ansible.cfg           # Ansible configuration
├── inventory/
│   └── hosts.yml        # Server inventory (starbase)
└── playbooks/
    └── deploy.yml       # Deployment playbook
```

## Quick Deployment

### If you have passwordless sudo on starbase:

```bash
./deploy.sh
```

### If you need to enter sudo password:

```bash
./deploy.sh --sudo
```

or

```bash
./deploy.sh -K
```

This will prompt you for your sudo password on starbase.

## Manual Deployment

If you prefer to run the playbook manually:

```bash
cd ansible

# With passwordless sudo
ansible-playbook playbooks/deploy.yml

# With sudo password prompt
ansible-playbook playbooks/deploy.yml --ask-become-pass
```

## What It Does

The deployment playbook:
1. **Connects** to starbase as your user
2. **Uses sudo** to become root (configured via `become: yes` in the playbook)
3. Creates a directory `/usr/share/nginx/html/visualize-things/` on starbase
4. Syncs all `.html` files to the server
5. Sets proper permissions for nginx (owner: nginx, group: nginx)
6. Excludes `.git`, `.claude`, and `ansible` directories

### How sudo/root access works:

- **Inventory** (`inventory/hosts.yml`): Sets `ansible_become: yes`
- **Playbook** (`playbooks/deploy.yml`): Contains `become: yes`
- **Behavior**: Ansible will run `sudo` commands on the remote system
- **Password**: Use `-K` flag if your user requires a password for sudo

## Customization

### Change nginx directory

Edit `ansible/inventory/hosts.yml` and modify the `nginx_html_dir` variable:

```yaml
starbase:
  ansible_host: starbase
  nginx_html_dir: /var/www/html  # Change this
```

### Change remote user

Edit `ansible/inventory/hosts.yml` and modify `ansible_user`:

```yaml
starbase:
  ansible_user: your_username  # Change this
```

## Accessing Your Visualizations

After deployment, access your visualizations at:
- http://starbase/visualize-things/

Individual files:
- http://starbase/visualize-things/lissajous-curve.html
- http://starbase/visualize-things/particle-simulator.html
- http://starbase/visualize-things/crazy-icons.html
- etc.

## Troubleshooting

### Error: "chown failed: failed to look up user nginx"

This means the `nginx` user doesn't exist on your system. Different systems use different user names for the web server.

**To fix:** Edit `ansible/inventory/hosts.yml` and change `web_user` and `web_group`:

```yaml
starbase:
  web_user: www-data    # Change from 'nginx' to your system's web user
  web_group: www-data   # Change from 'nginx' to your system's web group
```

**Common web server users by system:**
- **Debian/Ubuntu**: `www-data`
- **RHEL/CentOS/Fedora**: `nginx` or `apache`
- **Arch Linux**: `http`
- **macOS**: `_www`

**To find your web server user:**
```bash
# SSH to starbase and run:
ps aux | grep -E 'nginx|apache|httpd' | grep -v grep
# Look at the first column to see which user is running the web server
```

**Alternative - Skip user/group ownership:**

If you just want to deploy without setting specific ownership, you can remove the owner/group settings from the playbook temporarily, or set them to your own user:

```yaml
starbase:
  web_user: "{{ ansible_user }}"   # Use your own user
  web_group: "{{ ansible_user }}"  # Use your own user
```

### Error: "Permission denied" when accessing files

Make sure nginx has read access to `/usr/share/nginx/html/visualize-things/` and the deployment worked correctly. Check nginx error logs:

```bash
ssh starbase
sudo tail -f /var/log/nginx/error.log
```

### Error: SSH connection issues

Make sure you can SSH to starbase:
```bash
ssh starbase
```

If this doesn't work, you may need to:
1. Add starbase to your SSH config (`~/.ssh/config`)
2. Set up SSH keys for passwordless authentication
3. Use the full hostname or IP address in `ansible/inventory/hosts.yml`

### Error: "Permission denied" during Deploy HTML files

If you see rsync errors like `mkstemp failed: Permission denied`, this means the deployment directory is owned by root but rsync is connecting as your regular user.

**Fix:** The playbook uses `rsync_path: "sudo rsync"` to run rsync with sudo on the remote side. Make sure:
1. You're using `./deploy.sh --sudo` or `./deploy.sh -K` to provide the sudo password
2. Your user has passwordless sudo, OR you provided the password when prompted
3. Your user's sudo configuration allows running rsync

### Deployment hangs on "Deploy HTML files" task

If the synchronize task hangs, it's usually because:

1. **SSH authentication issues**: Make sure you can SSH to starbase without being prompted for a password
   ```bash
   ssh starbase whoami
   ```
   If this prompts for a password, set up SSH keys

2. **rsync not installed**: The synchronize module requires rsync on both local and remote systems
   ```bash
   # Check if rsync is installed on starbase
   ssh starbase which rsync

   # Install if missing (Debian/Ubuntu)
   ssh starbase sudo apt-get install rsync

   # Install if missing (RHEL/CentOS)
   ssh starbase sudo yum install rsync
   ```

3. **Network/firewall issues**: Ensure SSH port (22) is open and accessible
