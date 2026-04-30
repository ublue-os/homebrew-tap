cask "asusctl-linux" do
  arch arm: "arm64", intel: "amd64"

  version "6.3.7,2"
  sha256 arm64_linux:  "1f77ef14fc4e24d8a67dbeedcf328cc443e5066854af5939f0f3c070f87af900",
         x86_64_linux: "95467dfaa2225529773cc5020eb8d4c82392ab55c2dec01458cd4d67289001bd"

  release_tag = "asusctl-#{version.csv.first}-#{version.csv.second}"
  release_root = "asusctl-#{version.csv.first}-ubuntu-22.04-#{arch}"

  url "https://github.com/daegalus/linux-app-builds/releases/download/#{release_tag}/#{release_root}.tar.gz",
      verified: "github.com/daegalus/linux-app-builds/"
  name "asusctl"
  desc "ASUS laptop control CLI and immutable-friendly system daemon payload"
  homepage "https://gitlab.com/asus-linux/asusctl"

  livecheck do
    url "https://api.github.com/repos/daegalus/linux-app-builds/releases/latest"
    strategy :json do |json|
      tag = json["tag_name"].to_s
      match = tag.match(/^asusctl-(\d+(?:\.\d+)+)-(\d+)$/)
      next if match.nil?

      "#{match[1]},#{match[2]}"
    end
  end

  binary "#{release_root}/usr/bin/asusctl"
  binary "#{release_root}/usr/bin/asusd"
  binary "#{release_root}/usr/bin/asus-shutdown"

  postflight do
    release_dir = "#{staged_path}/#{release_root}"
    root_prefix = "/opt/ublue-asusctl"
    root_bin_dir = "#{root_prefix}/bin"
    root_share_dir = "#{root_prefix}/share"
    root_asusd_dir = "#{root_share_dir}/asusd"
    systemd_dir = "/etc/systemd/system"
    udev_dir = "/etc/udev/rules.d"
    dbus_dir = "/etc/dbus-1/system.d"
    config_dir = "/etc/asusd"
    asusd_service_src = "#{release_dir}/usr/lib/systemd/system/asusd.service"
    asus_shutdown_service_src = "#{release_dir}/usr/lib/systemd/system/asus-shutdown.service"

    getenforce = %w[/usr/sbin/getenforce /usr/bin/getenforce /bin/getenforce].find do |path|
      File.executable?(path)
    end
    restorecon = %w[/usr/sbin/restorecon /usr/bin/restorecon /bin/restorecon].find do |path|
      File.executable?(path)
    end
    semanage = %w[/usr/sbin/semanage /usr/bin/semanage /bin/semanage].find do |path|
      File.executable?(path)
    end
    chcon = %w[/usr/sbin/chcon /usr/bin/chcon /bin/chcon].find do |path|
      File.executable?(path)
    end
    systemctl = %w[/usr/bin/systemctl /bin/systemctl].find do |path|
      File.executable?(path)
    end
    udevadm = %w[/usr/bin/udevadm /bin/udevadm].find do |path|
      File.executable?(path)
    end

    ohai "Installing ASUS daemon payload under #{root_prefix}"

    system "sudo", "install", "-d",
           root_bin_dir, root_asusd_dir, systemd_dir, udev_dir, dbus_dir, config_dir
    system "sudo", "install", "-Dm0755",
           "#{release_dir}/usr/bin/asusd",
           "#{root_bin_dir}/asusd"
    system "sudo", "install", "-Dm0755",
           "#{release_dir}/usr/bin/asus-shutdown",
           "#{root_bin_dir}/asus-shutdown"
    system "sudo", "cp", "-a", "#{release_dir}/usr/share/asusd/.", root_asusd_dir
    asusd_service = File.read(asusd_service_src)
    asusd_service.gsub!("Environment=ASUSD_EXEC=/usr/bin/asusd\n", "")
    asusd_service.gsub!("ExecStart=${ASUSD_EXEC}", "ExecStart=#{root_bin_dir}/asusd")
    File.write("#{staged_path}/asusd.service", asusd_service)

    asus_shutdown_service = File.read(asus_shutdown_service_src)
    asus_shutdown_service.gsub!("Environment=ASUS_SHUTDOWN_EXEC=/usr/bin/asus-shutdown\n", "")
    asus_shutdown_service.gsub!("ExecStart=${ASUS_SHUTDOWN_EXEC}", "ExecStart=#{root_bin_dir}/asus-shutdown")
    File.write("#{staged_path}/asus-shutdown.service", asus_shutdown_service)

    system "sudo", "install", "-Dm0644",
           "#{staged_path}/asusd.service",
           "#{systemd_dir}/asusd.service"
    system "sudo", "install", "-Dm0644",
           "#{staged_path}/asus-shutdown.service",
           "#{systemd_dir}/asus-shutdown.service"
    system "sudo", "install", "-Dm0644",
           "#{release_dir}/usr/lib/udev/rules.d/99-asusd.rules",
           "#{udev_dir}/99-asusd.rules"
    system "sudo", "install", "-Dm0644",
           "#{release_dir}/usr/share/dbus-1/system.d/asusd.conf",
           "#{dbus_dir}/asusd.conf"

    File.write("#{staged_path}/asusd.env", <<~EOS)
      ASUSD_DATA_DIR=#{root_asusd_dir}
      ASUSCTL_AURA_SUPPORT_PATH=#{root_asusd_dir}/aura_support.ron
      ASUSCTL_DATA_DIRS=#{root_share_dir}
    EOS

    system "sudo", "install", "-Dm0644",
           "#{staged_path}/asusd.env",
           "#{config_dir}/asusd.env"

    selinux_mode = if getenforce
      IO.popen([getenforce], &:read).strip
    else
      "Disabled"
    end

    if selinux_mode != "Disabled"
      resolved_root_bin = begin
        File.realpath(root_bin_dir)
      rescue
        root_bin_dir
      end
      bin_pattern = "#{resolved_root_bin}(/.*)?"

      if semanage
        added = system "sudo", semanage, "fcontext", "-a", "-t", "bin_t", bin_pattern
        system "sudo", semanage, "fcontext", "-m", "-t", "bin_t", bin_pattern unless added
      elsif chcon
        system "sudo", chcon, "-R", "-t", "bin_t", resolved_root_bin
      end

      if restorecon
        [root_prefix, systemd_dir, udev_dir, dbus_dir, config_dir].each do |path|
          system "sudo", restorecon, "-RFv", path if File.exist?(path)
        end
      end
    end

    system "sudo", systemctl, "daemon-reload" if systemctl
    system "sudo", udevadm, "control", "--reload" if udevadm
  end

  uninstall_preflight do
    root_prefix = "/opt/ublue-asusctl"
    root_bin_dir = "#{root_prefix}/bin"
    systemd_dir = "/etc/systemd/system"
    udev_dir = "/etc/udev/rules.d"
    dbus_dir = "/etc/dbus-1/system.d"
    config_dir = "/etc/asusd"

    getenforce = %w[/usr/sbin/getenforce /usr/bin/getenforce /bin/getenforce].find do |path|
      File.executable?(path)
    end
    restorecon = %w[/usr/sbin/restorecon /usr/bin/restorecon /bin/restorecon].find do |path|
      File.executable?(path)
    end
    semanage = %w[/usr/sbin/semanage /usr/bin/semanage /bin/semanage].find do |path|
      File.executable?(path)
    end
    systemctl = %w[/usr/bin/systemctl /bin/systemctl].find do |path|
      File.executable?(path)
    end
    udevadm = %w[/usr/bin/udevadm /bin/udevadm].find do |path|
      File.executable?(path)
    end

    system "sudo", systemctl, "disable", "--now", "asus-shutdown.service" if systemctl
    system "sudo", systemctl, "disable", "--now", "asusd.service" if systemctl

    selinux_mode = if getenforce
      IO.popen([getenforce], &:read).strip
    else
      "Disabled"
    end

    if selinux_mode != "Disabled" && semanage
      resolved_root_bin = begin
        File.realpath(root_bin_dir)
      rescue
        root_bin_dir
      end
      system "sudo", semanage, "fcontext", "-d", "#{resolved_root_bin}(/.*)?"
    end

    system "sudo", "rm", "-f", "#{systemd_dir}/asusd.service"
    system "sudo", "rm", "-f", "#{systemd_dir}/asus-shutdown.service"
    system "sudo", "rm", "-f", "#{udev_dir}/99-asusd.rules"
    system "sudo", "rm", "-f", "#{dbus_dir}/asusd.conf"
    system "sudo", "rm", "-f", "#{config_dir}/asusd.env"
    system "sudo", "rm", "-rf", root_prefix
    system "sudo", "rmdir", config_dir if Dir.exist?(config_dir) && Dir.empty?(config_dir)

    system "sudo", systemctl, "daemon-reload" if systemctl
    system "sudo", udevadm, "control", "--reload" if udevadm
    system "sudo", restorecon, "-RFv", "/opt", "/var/opt" if restorecon && selinux_mode != "Disabled"
  end

  caveats <<~EOS
    Root-only daemon files were installed to:
      /opt/ublue-asusctl
      /etc/asusd/asusd.env
      /etc/systemd/system/asusd.service
      /etc/systemd/system/asus-shutdown.service
      /etc/udev/rules.d/99-asusd.rules
      /etc/dbus-1/system.d/asusd.conf

    On Bluefin and Bazzite, /opt resolves into writable /var storage, so the
    daemon payload does not depend on a writable /usr tree.

    To activate the system services:
      sudo systemctl enable --now asusd.service asus-shutdown.service
      sudo udevadm control --reload
      sudo udevadm trigger

    For the GUI and user daemon:
      brew install --cask rog-control-center-linux
  EOS
end
