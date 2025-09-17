cask "containerd-not-working" do
  arch arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "2.1.4"
  sha256 arm64_linux:  "846d13bc2bf1c01ae2f20d13beb9b3a1e50b52c86e955b4ac7d658f5847f2b0e",
         x86_64_linux: "316d510a0428276d931023f72c09fdff1a6ba81d6cc36f31805fea6a3c88f515"

  url "https://github.com/containerd/containerd/releases/download/v#{version}/containerd-#{version}-#{os}-#{arch}.tar.gz"
  name "containerd"
  desc "Open and reliable container runtime"
  homepage "https://containerd.io/"

  livecheck do
    url "https://github.com/containerd/containerd.git"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :github_releases do |json, regex|
      json.map do |release|
        next if release["draft"] || release["prerelease"]

        match = release["tag_name"]&.match(regex)
        next if match.blank?

        match[1]
      end
    end
  end

  auto_updates true

  # conflicts_with "docker"

  binary "bin/containerd"
  binary "bin/containerd-shim-runc-v2"
  binary "bin/containerd-stress"
  binary "bin/ctr"
  artifact "containerd.service", target: "#{Dir.home}/.config/systemd/user/containerd.service"

  preflight do
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
