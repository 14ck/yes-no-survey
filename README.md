# Yes/No Survey App

A simple, elegant survey application built with SvelteKit, Tailwind CSS, and DaisyUI.

## Features

- **Simple Interface**: Two big buttons for Yes/No responses
- **Name Collection**: Modal popup to collect respondent names
- **Live Results**: Real-time display of all responses in a table
- **Beautiful UI**: Modern design using DaisyUI themes
- **Responsive**: Works on desktop and mobile devices

## Tech Stack

- **SvelteKit** - Full-stack framework
- **Svelte 5** - Latest version with runes API
- **Tailwind CSS** - Utility-first styling
- **DaisyUI** - Component library
- **TypeScript** - Type safety
- **Docker** - Containerization for easy deployment

## Development

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Docker Deployment (Proxmox)

### Build and Run with Docker Compose

```bash
docker compose up -d --build
```

The app will be available at `http://<container-ip>:3000`

### Proxmox LXC Container Setup

1. Create a new LXC container (Ubuntu or Debian)
2. Install Docker and Docker Compose
3. Clone/copy this project to the container
4. Run `docker compose up -d --build`
5. Access via container IP on port 3000

### Port Forwarding (Optional)

If deploying on an isolated network (like vmbr1), add port forwarding on the Proxmox host:

```bash
# Forward port 3000 from Proxmox host to container
iptables -t nat -A PREROUTING -i vmbr0 -p tcp --dport 3000 -j DNAT --to-destination <container-ip>:3000
iptables -t nat -A OUTPUT -p tcp -d <proxmox-host-ip> --dport 3000 -j DNAT --to-destination <container-ip>:3000
iptables -I FORWARD -i vmbr0 -o vmbr1 -d <container-ip> -j ACCEPT
iptables -I FORWARD -i vmbr1 -o vmbr0 -s <container-ip> -m state --state RELATED,ESTABLISHED -j ACCEPT

# Save rules
netfilter-persistent save
```

Then access at `http://<proxmox-host-ip>:3000`

### Nginx Proxy Manager Setup

To access via a custom domain:

1. **Add DNS record in Pi-hole**:
   - Domain: `survey.local` (or your choice)
   - IP: Your Proxmox host IP or container IP

2. **Create Proxy Host in NPM**:
   - Domain: `survey.local`
   - Forward to: `<container-ip>:3000`
   - Optional: Enable SSL with self-signed cert

## Configuration

### Change Port

Edit `docker-compose.yml`:

```yaml
ports:
  - "8080:3000"  # Change 8080 to desired port
```

### Change Theme

Edit `src/app.html` and add `data-theme` attribute:

```html
<html lang="en" data-theme="dark">
```

Available themes: `light`, `dark`, `cupcake` (see `tailwind.config.js` for more)

## Notes

- Responses are stored in memory (not persisted)
- For persistent storage, add a database (SQLite, PostgreSQL, etc.)
- Consider adding authentication for production use
- This is designed for internal network use (not internet-facing)

## Future Enhancements

- Persist responses to database
- Add authentication
- Export responses to CSV
- Add more question types
- Real-time updates with WebSockets
- Analytics and charts
