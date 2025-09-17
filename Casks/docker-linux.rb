cask "docker-linux-notworking" do
  arch arm: "aarch64", intel: "x86_64"
  os linux: "linux"

  version "28.4.0"
  sha256 arm64_linux:  "059416f4fe7465bdedbabd6d34db524e6e3bef65f3b61caa42a3d8ca94150ed2",
         x86_64_linux: "21516934188f06d0e5f232cbde8112701f6d82899016240bc7a5d619f6b0059c"

  url "https://download.docker.com/#{os}/static/stable/#{arch}/docker-#{version}.tgz"
  name "Docker Engine"
  name "Docker Community Edition"
  name "Docker CE"
  desc "Tool to build and share containerised applications and microservices"
  homepage "https://docs.docker.com/engine/install/binaries/"

  livecheck do
    url "https://github.com/docker/cli.git"
    regex(/^v?(\d+(?:\.\d+)+)(?:[._-]ce)?$/i)
    strategy :git
  end

  auto_updates true
  #conflicts_with "docker"

  #binary "docker/containerd"
  #binary "docker/containerd-shim-runc-v2"
  #binary "docker/ctr"
  binary "docker/dockerd"
  binary "docker/docker"
  binary "docker/docker-init"
  binary "docker/docker-proxy"
  binary "docker/runc"
  artifact "docker.service", target: "#{Dir.home}/.config/systemd/user/docker.service"
  artifact "docker.socket", target: "#{Dir.home}/.config/systemd/user/docker.socket"
  #artifact "containerd.service", target: "#{Dir.home}/.config/systemd/user/containerd.service"

  preflight do
    File.write("#{staged_path}/docker.service", <<~EOS)
      [Unit]
      Description=Docker Application Container Engine
      Documentation=https://docs.docker.com
      After=network-online.target nss-lookup.target docker.socket firewalld.service containerd.service time-set.target
      Wants=network-online.target containerd.service
      Requires=docker.socket
      StartLimitBurst=3
      StartLimitIntervalSec=60

      [Service]
      Type=notify
      # the default is not to use systemd for cgroups because the delegate issues still
      # exists and systemd currently does not support the cgroup feature set required
      # for containers run by docker
      ExecStart=#{HOMEBREW_PREFIX}/bin/dockerd -H fd:// --containerd=#{ENV["XDG_RUNTIME_DIR"]}/containerd.sock
      ExecReload=/bin/kill -s HUP $MAINPID
      TimeoutStartSec=0
      RestartSec=2
      Restart=always

      # Having non-zero Limit*s causes performance problems due to accounting overhead
      # in the kernel. We recommend using cgroups to do container-local accounting.
      LimitNPROC=infinity
      LimitCORE=infinity

      # Comment TasksMax if your systemd version does not support it.
      # Only systemd 226 and above support this option.
      TasksMax=infinity

      # set delegate yes so that systemd does not reset the cgroups of docker containers
      Delegate=yes

      # kill only the docker process, not all processes in the cgroup
      KillMode=process
      OOMScoreAdjust=-500

      [Install]
      WantedBy=multi-user.target
    EOS

    File.write("#{staged_path}/docker.socket", <<~EOS)
      [Unit]
      Description=Docker Socket for the API

      [Socket]
      # If /var/run is not implemented as a symlink to /run, you may need to
      # specify ListenStream=/var/run/docker.sock instead.
      ListenStream=#{ENV["XDG_RUNTIME_DIR"]}/docker.sock
      SocketMode=0660
      SocketUser=#{ENV["USER"]}
      SocketGroup=docker

      [Install]
      WantedBy=sockets.target
    EOS

    File.write("#{staged_path}/containerd.service", <<~EOS)
      # Copyright The containerd Authors.
      #
      # Licensed under the Apache License, Version 2.0 (the "License");
      # you may not use this file except in compliance with the License.
      # You may obtain a copy of the License at
      #
      #     http://www.apache.org/licenses/LICENSE-2.0
      #
      # Unless required by applicable law or agreed to in writing, software
      # distributed under the License is distributed on an "AS IS" BASIS,
      # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
      # See the License for the specific language governing permissions and
      # limitations under the License.

      [Unit]
      Description=containerd container runtime
      Documentation=https://containerd.io
      After=network.target local-fs.target dbus.service

      [Service]
      #uncomment to enable the experimental sbservice (sandboxed) version of containerd/cri integration
      #Environment="ENABLE_CRI_SANDBOXES=sandboxed"
      ExecStartPre=-/sbin/modprobe overlay
      ExecStart=#{HOMEBREW_PREFIX}/bin/containerd

      Type=notify
      Delegate=yes
      KillMode=process
      Restart=always
      RestartSec=5
      # Having non-zero Limit*s causes performance problems due to accounting overhead
      # in the kernel. We recommend using cgroups to do container-local accounting.
      LimitNPROC=infinity
      LimitCORE=infinity
      LimitNOFILE=infinity
      # Comment TasksMax if your systemd version does not supports it.
      # Only systemd 226 and above support this version.
      TasksMax=infinity
      OOMScoreAdjust=-999

      [Install]
      WantedBy=multi-user.target
    EOS
  end

  caveats <<~EOS
    You need to run the following commands to finish setting up Docker:
      systemctl --user enable containerd.service
      systemctl --user start containerd.service
      systemctl --user enable docker.service
      systemctl --user start docker.service
      systemctl --user enable docker.socket
      systemctl --user start docker.socket
      sudo ln -s /var/run/docker.sock /var/run/users/$UID/docker.sock
    You may need to log out and back in for the group changes to take effect.
  EOS
end
