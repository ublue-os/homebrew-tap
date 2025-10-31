cask "bluefin-wallpapers-extra" do
  version "2025-10-29"
  sha256 "8893969a3e4bc5de206dcbbb3fdfdaf356913cd4e3bf5add875b86ace5c9cb68"

  url "https://github.com/projectbluefin/artwork/releases/latest/download/bluefin-wallpapers-extra.tar.zstd"
  name "bluefin-wallpapers-extra"
  desc "Extra Wallpapers for Bluefin"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    regex(/v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_latest
  end

  # Detect if GNOME is actually running
  is_gnome = ENV["XDG_CURRENT_DESKTOP"]&.include?("GNOME") ||
             ENV["DESKTOP_SESSION"]&.include?("gnome") ||
             (File.exist?("/usr/bin/gnome-shell") && `pgrep -x gnome-shell 2>/dev/null`.strip != "")

  # Detect if KDE is running
  is_kde = ENV["XDG_CURRENT_DESKTOP"]&.include?("KDE") ||
           ENV["DESKTOP_SESSION"]&.include?("kde") ||
           File.exist?("/usr/bin/plasmashell")

  # Only depend on ImageMagick if not on GNOME or KDE
  depends_on formula: "imagemagick" if !is_gnome && !is_kde

  destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"
  kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin"

  if is_kde
    Dir.glob("#{staged_path}/kde/*").each do |file|
      artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
    end
  else
    Dir.glob("#{staged_path}/gnome/images/*").each do |file|
      folder = File.basename(file, File.extname(file)).gsub(/-night|-day/, "")
      artifact file, target: "#{destination_dir}/#{folder}/#{File.basename(file)}"
    end

    Dir.glob("#{staged_path}/gnome/gnome-background-properties/*").each do |file|
      artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
    end
  end

  preflight do
    # Detect if GNOME is actually running
    is_gnome = ENV["XDG_CURRENT_DESKTOP"]&.include?("GNOME") ||
               ENV["DESKTOP_SESSION"]&.include?("gnome") ||
               (File.exist?("/usr/bin/gnome-shell") && `pgrep -x gnome-shell 2>/dev/null`.strip != "")

    # Detect if KDE is running
    is_kde = ENV["XDG_CURRENT_DESKTOP"]&.include?("KDE") ||
             ENV["DESKTOP_SESSION"]&.include?("kde") ||
             File.exist?("/usr/bin/plasmashell")

    Dir.glob("#{staged_path}/**/*.xml").each do |file|
      next unless File.file?(file)

      contents = File.read(file)
      contents.gsub!("~", Dir.home)
      # Replace image extensions for converted files if not GNOME/KDE
      contents.gsub!(/\.(avif|jxl)(?=['"])/, ".png") if !is_gnome && !is_kde
      File.write(file, contents)
    end
  end

  postflight do
    # Detect if GNOME is actually running
    is_gnome = ENV["XDG_CURRENT_DESKTOP"]&.include?("GNOME") ||
               ENV["DESKTOP_SESSION"]&.include?("gnome") ||
               (File.exist?("/usr/bin/gnome-shell") && `pgrep -x gnome-shell 2>/dev/null`.strip != "")

    # Detect if KDE is running
    is_kde = ENV["XDG_CURRENT_DESKTOP"]&.include?("KDE") ||
             ENV["DESKTOP_SESSION"]&.include?("kde") ||
             File.exist?("/usr/bin/plasmashell")

    wallpaper_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"

    # Convert KDE wallpapers to PNG if not on KDE or GNOME
    if !is_gnome && !is_kde
      desktop_env = ENV["XDG_CURRENT_DESKTOP"] || ENV["DESKTOP_SESSION"] || "unknown"
      puts "Converting wallpapers to PNG for #{desktop_env} desktop..."

      # Prefer ImageMagick v7 'magick', fall back to 'convert' if necessary
      convert_cmd = `which magick`.strip
      if convert_cmd.empty?
        convert_cmd = `which convert`.strip
      end
      convert_cmd = "/home/linuxbrew/.linuxbrew/bin/magick" if convert_cmd.empty? && File.exist?("/home/linuxbrew/.linuxbrew/bin/magick")
      convert_cmd = "/home/linuxbrew/.linuxbrew/bin/convert" if convert_cmd.empty? && File.exist?("/home/linuxbrew/.linuxbrew/bin/convert")

      # Create a list of files to convert
      files_to_convert = Dir.glob("#{wallpaper_dir}/**/*.avif") + Dir.glob("#{wallpaper_dir}/**/*.jxl")

      if convert_cmd.empty?
        puts "No 'magick' or 'convert' found in PATH; skipping image conversion."
      elsif files_to_convert.empty?
        puts "No AVIF or JXL wallpapers to convert for #{desktop_env} desktop"
      else
        puts "Using #{convert_cmd} to convert images"
        if File.basename(convert_cmd) == "convert"
          puts "WARNING: 'convert' is deprecated in ImageMagick 7; consider installing 'magick'."
        end

        # Determine number of threads (use number of CPU cores, max 6 to avoid overwhelming system)
        require "etc"
        num_threads = [Etc.nprocessors, 6].min

        # Convert files concurrently
        threads = []
        files_to_convert.each_slice((files_to_convert.size.to_f / num_threads).ceil) do |file_batch|
          threads << Thread.new do
            file_batch.each do |file|
              next unless File.file?(file)

              filename = File.basename(file)
              output_file = "#{File.dirname(file)}/#{filename.gsub(/\.(avif|jxl)$/i, ".png")}"

              puts "Converting #{filename} to PNG..."

              # Convert image to PNG using ImageMagick
              result = system(convert_cmd, file, output_file)

              if result && File.exist?(output_file)
                puts "Successfully converted #{filename}, removing original..."
                File.delete(file)
              else
                puts "WARNING: Failed to convert #{filename}"
              end
            end
          end
        end

        # Wait for all threads to complete
        threads.each(&:join)
        puts "Wallpaper conversion complete!"
      end
    end
  end
end
