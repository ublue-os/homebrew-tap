cask "asusctl-linux" do
  arch arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "6.5.0,4"
  sha256 arm:          "04b2a6e7a1858d9af33423f67cca335b3b46a89b9a6077c16a3f4f244c0a02d7",
         intel:        "91aa192f9b1861dce9ea3077bd7bf839acf97c5349d26435e699e49785fd21e6",
         arm64_linux:  "04b2a6e7a1858d9af33423f67cca335b3b46a89b9a6077c16a3f4f244c0a02d7",
         x86_64_linux: "91aa192f9b1861dce9ea3077bd7bf839acf97c5349d26435e699e49785fd21e6"

  release_tag = "asusctl-#{version.csv.first}-#{version.csv.second}"
  release_root = "asusctl-#{version.csv.first}-ubuntu-22.04-#{arch}"

  url "https://github.com/daegalus/linux-app-builds/releases/download/#{release_tag}/#{release_root}.tar.gz"
  name "asusctl"
  desc "ASUS laptop control CLI and immutable-friendly system daemon payload"
  homepage "https://github.com/OpenGamingCollective/asusctl"

  livecheck do
    url "https://api.github.com/repos/daegalus/linux-app-builds/releases/latest"
    strategy :json do |json|
      tag = json["tag_name"].to_s
      match = tag.match(/^asusctl-(\d+(?:\.\d+)+)-(\d+)$/)
      next if match.nil?

      "#{match[1]},#{match[2]}"
    end
  end

  binary "asusctl/usr/bin/asusctl"
  binary "asusctl/usr/bin/asusd"
  binary "asusctl/usr/bin/asus-shutdown"

  preflight_steps do
    move "asusctl-*-ubuntu-22.04-*", "asusctl", source_glob: true
  end

  postflight_steps do
    # Generate files in the existing stage without predeclaring them as directories.
    run "/bin/sed", args:        ["-e", "/^Environment=ASUSD_EXEC=/d",
                                  "-e", "s|^ExecStart=.*|ExecStart=/opt/ublue-asusctl/bin/asusd|",
                                  "{{staged_path}}/asusctl/usr/lib/systemd/system/asusd.service"],
                    stdout_path: "asusd.service"
    run "/bin/sed", args:        ["-e", "/^Environment=ASUS_SHUTDOWN_EXEC=/d",
                                  "-e",
                                  "s|^ExecStart=.*|ExecStart=/opt/ublue-asusctl/bin/asus-shutdown|",
                                  "{{staged_path}}/asusctl/usr/lib/systemd/system/asus-shutdown.service"],
                    stdout_path: "asus-shutdown.service"
    write_file "asusd.env", <<~EOS
      ASUSD_DATA_DIR=/opt/ublue-asusctl/share/asusd
      ASUSCTL_AURA_SUPPORT_PATH=/opt/ublue-asusctl/share/asusd/aura_support.ron
      ASUSCTL_DATA_DIRS=/opt/ublue-asusctl/share
    EOS
    run "/bin/sh", args: ["-eu", "-c", <<~SH, "--", "{{staged_path}}"], sudo: true
      PATH=/usr/sbin:/usr/bin:/bin
      stage=$1
      root=/opt/ublue-asusctl
      install -d "$root/bin" "$root/share/asusd" /etc/systemd/system /etc/udev/rules.d /etc/dbus-1/system.d /etc/asusd
      install -Dm0755 "$stage/asusctl/usr/bin/asusd" "$root/bin/asusd"
      install -Dm0755 "$stage/asusctl/usr/bin/asus-shutdown" "$root/bin/asus-shutdown"
      cp -a "$stage/asusctl/usr/share/asusd/." "$root/share/asusd"
      install -Dm0644 "$stage/asusd.service" /etc/systemd/system/asusd.service
      install -Dm0644 "$stage/asus-shutdown.service" /etc/systemd/system/asus-shutdown.service
      install -Dm0644 "$stage/asusctl/usr/lib/udev/rules.d/99-asusd.rules" /etc/udev/rules.d/99-asusd.rules
      install -Dm0644 "$stage/asusctl/usr/share/dbus-1/system.d/asusd.conf" /etc/dbus-1/system.d/asusd.conf
      install -Dm0644 "$stage/asusd.env" /etc/asusd/asusd.env

      if command -v getenforce >/dev/null && [ "$(getenforce)" != Disabled ]; then
        if command -v semanage >/dev/null; then
          semanage fcontext -a -t bin_t "$root/bin(/.*)?" || semanage fcontext -m -t bin_t "$root/bin(/.*)?"
        elif command -v chcon >/dev/null; then
          chcon -R -t bin_t "$root/bin"
        fi
        if command -v restorecon >/dev/null; then
          restorecon -RFv "$root" /etc/systemd/system /etc/udev/rules.d /etc/dbus-1/system.d /etc/asusd
        fi
      fi
      if command -v pkill >/dev/null; then
        # Reap a pre-upgrade asus-shutdown: it defers SIGTERM by design and ships
        # SendSIGKILL=no, so `disable --now` from an older Cask leaves it behind and
        # systemd then refuses to start the new unit while it exists.
        pkill -KILL -x asus-shutdown || true
        pkill -KILL -x asusd || true
      fi
      if command -v systemctl >/dev/null; then systemctl daemon-reload || true; fi
      if command -v systemctl >/dev/null; then systemctl reset-failed asus-shutdown.service asusd.service || true; fi
      if command -v udevadm >/dev/null; then udevadm control --reload || true; fi
    SH
  end

  uninstall_preflight_steps do
    run "/bin/sh", args: ["-eu", "-c", <<~'SH'], sudo: true
      PATH=/usr/sbin:/usr/bin:/bin
      if command -v systemctl >/dev/null; then
        systemctl disable asus-shutdown.service asusd.service || true
        systemctl stop asusd.service || true
      fi
      if command -v pkill >/dev/null; then
        # asus-shutdown defers SIGTERM by design and ships SendSIGKILL=no, so only
        # SIGKILL reaps it; otherwise it outlives uninstalls and blocks future starts.
        pkill -KILL -x asus-shutdown || true
        pkill -KILL -x asusd || true
      fi
      selinux=Disabled
      if command -v getenforce >/dev/null; then selinux=$(getenforce); fi
      if [ "$selinux" != Disabled ] && command -v semanage >/dev/null; then
        semanage fcontext -d "/opt/ublue-asusctl/bin(/.*)?" || true
      fi
      rm -f /etc/systemd/system/asusd.service /etc/systemd/system/asus-shutdown.service \
        /etc/udev/rules.d/99-asusd.rules /etc/dbus-1/system.d/asusd.conf /etc/asusd/asusd.env
      rm -rf /opt/ublue-asusctl
      rmdir /etc/asusd 2>/dev/null || true
      if command -v systemctl >/dev/null; then systemctl daemon-reload || true; fi
      if command -v udevadm >/dev/null; then udevadm control --reload || true; fi
      if [ "$selinux" != Disabled ] && command -v restorecon >/dev/null; then
        restorecon -RFv /opt /var/opt || true
      fi
    SH
  end

  caveats <<~EOS
    Root-only daemon files were installed to:
      /opt/ublue-asusctl
      /etc/asusd/asusd.env
      /etc/systemd/system/asusd.service
      /etc/systemd/system/asus-shutdown.service
      /etc/udev/rules.d/99-asusd.rules
      /etc/dbus-1/system.d/asusd.conf

    On Aurora, Bluefin and Bazzite, /opt resolves into writable /var storage, so the
    daemon payload does not depend on a writable /usr tree.

    To activate the system services:
      sudo systemctl enable --now asusd.service asus-shutdown.service
      sudo udevadm control --reload
      sudo udevadm trigger

    For the GUI and user daemon:
      brew install --cask rog-control-center-linux
  EOS
end
