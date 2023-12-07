#!/bin/bash
# curl https://raw.githubusercontent.com/artyomb/servers/main/new/zfs_install.sh | sh

# https://github.com/TrilliumIT/docker-zfs-plugin
apt install -y zfsutils-linux

truncate -s 1G /swarm.pool1
# resize pool size
# truncate -s +1G /swarm.pool1
# du -h --apparent-size /swarm.pool1
# IF not working:
# zpool status swarm_pool -g
# zpool replace swarm_pool 9738906798654662221 /swarm.pool1
# zpool status swarm_pool -g
# zpool online -e swarm_pool 11631298782208812051

# TODO: quota, refquota
# zfs get refquota,quota,reservation swarm_pool/graph_node_db
# zfs set reservation=300MB swarm_pool/graph_node_db
# zfs set reservation=200MB swarm_pool/graph_node_db2

zpool create -f swarm_pool /swarm.pool1

zfs set mountpoint=/var/lib/docker-volumes/zfs/swarm_pool swarm_pool

# zfs send swarm_pool/fs@snap | gzip > backupfile.gz
# gzip -d -c backupfile.gz | zfs receive -F cvpool/sunday

wget https://github.com/TrilliumIT/docker-zfs-plugin/releases/download/v1.0.5/docker-zfs-plugin
cp docker-zfs-plugin /usr/local/bin/
chmod +x /usr/local/bin/docker-zfs-plugin

wget https://raw.githubusercontent.com/TrilliumIT/docker-zfs-plugin/master/docker-zfs-plugin.service

sed -i 's/zfs\/tank/zfs\/swarm_pool/g' docker-zfs-plugin.service
sed -i 's/tank\/docker-volumes/swarm_pool/g' docker-zfs-plugin.service
cp docker-zfs-plugin.service /etc/systemd/system

systemctl daemon-reload && systemctl enable docker-zfs-plugin.service && systemctl start docker-zfs-plugin.service

# test backup volume
docker volume create -d zfs -o compression=lz4 -o dedup=on --name=swarm_pool/data


# SANOID ===========================================================================
apt install -y sanoid
#(crontab -l; echo "* * * * * (TZ=UTC sanoid --cron --debug 2>&1) > /ct.output")  | crontab -
tee /lib/systemd/system/sanoid.timer << END
[Unit]
Description=Run Sanoid Every 1 Minute

[Timer]
OnCalendar=*:0/1
Persistent=true

[Install]
WantedBy=timers.target
END

systemctl daemon-reload

mkdir /etc/sanoid
tee /etc/sanoid/sanoid.conf << END
[swarm_pool]
  recursive = yes
  process_children_only = yes
  frequent_period = 2
  frequently = 2
  hourly = 0
  daily = 0
  monthly = 0
  yearly = 0
  autosnap = yes
  autoprune = yes
  post_snapshot_script = /backup_snapshot.sh
  pruning_script = /prune_backup.sh
END

tee /prune_backup.sh << END
#!/bin/bash
date
echo "SANOID_SCRIPT: \${SANOID_SCRIPT}"
echo "SANOID_TARGET: \${SANOID_TARGET}"
echo "SANOID_SNAPNAME: \${SANOID_SNAPNAME}"

rm /\${SANOID_TARGET////_}@\${SANOID_SNAPNAME////_}_backup.gz
END
chmod +x /prune_backup.sh

tee /backup_snapshot.sh << END
#!/bin/bash
date

echo "SANOID_SCRIPT: ${SANOID_SCRIPT}"
echo "SANOID_TARGET: ${SANOID_TARGET}"
echo "SANOID_SNAPNAME: ${SANOID_SNAPNAME}"
echo "SANOID_SNAPNAME2: ${SANOID_SNAPNAME////_}"

if echo "${SANOID_SNAPNAME}" | grep -qv "hourly|frequently" ; then
    zfs send -R ${SANOID_SNAPNAME} | gzip --fast > /${SANOID_SNAPNAME////_}_backup.gz
fi

#rsync --delete -avzh /*.gz root@leostestzone.ru:/graph_node_backup
#/usr/sbin/syncoid -r --quiet --no-sync-snap root@unraid:SSD Buffalo/unRAID-Replication
END
chmod +x /backup_snapshot.sh

sanoid --monitor-health
zfs list -t snapshot
# zfs destroy tank/home/ahrens@now