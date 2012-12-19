require 'paperclip'

module Paperclip
  module Task
    def self.obtain_class
      class_name = ENV['CLASS'] || ENV['class']
      raise "Must specify CLASS" unless class_name
      class_name
    end

    def self.obtain_attachments(klass)
      klass = Paperclip.class_for(klass.to_s)
      name = ENV['ATTACHMENT'] || ENV['attachment']
      raise "Class #{klass.name} has no attachments specified" unless klass.respond_to?(:attachment_definitions)
      if !name.blank? && klass.attachment_definitions.keys.map(&:to_s).include?(name.to_s)
        [ name ]
      else
        klass.attachment_definitions.keys
      end
    end
  end
end

namespace :paperclip do
  desc "Refreshes both metadata and thumbnails."
  task :refresh => ["paperclip:refresh:metadata", "paperclip:refresh:thumbnails"]

  namespace :refresh do
    desc "Regenerates thumbnails for a given CLASS (and optional ATTACHMENT and STYLES splitted by comma)."
    task :thumbnails => :environment do
      errors = []
      klass = Paperclip::Task.obtain_class
      names = Paperclip::Task.obtain_attachments(klass)
      styles = (ENV['STYLES'] || ENV['styles'] || '').split(',').map(&:to_sym)
      names.each do |name|
        Paperclip.each_instance_with_attachment(klass, name) do |instance|
          instance.send(name).reprocess!(*styles)
          errors << [instance.id, instance.errors] unless instance.errors.blank?
        end
      end
      errors.each{|e| puts "#{e.first}: #{e.last.full_messages.inspect}" }
    end

    desc "Regenerates content_type/size metadata for a given CLASS (and optional ATTACHMENT)."
    task :metadata => :environment do
      klass = Paperclip::Task.obtain_class
      names = Paperclip::Task.obtain_attachments(klass)
      names.each do |name|
        Paperclip.each_instance_with_attachment(klass, name) do |instance|
          if file = instance.send(name).to_file(:original)
            instance.send("#{name}_file_name=", instance.send("#{name}_file_name").strip)
            instance.send("#{name}_content_type=", file.content_type.to_s.strip)
            instance.send("#{name}_file_size=", file.size) if instance.respond_to?("#{name}_file_size")
            if Rails.version >= "3.0.0"
              instance.save(:validate => false)
            else
              instance.save(false)
            end
          else
            true
          end
        end
      end
    end

    desc "Regenerates missing thumbnail styles for all classes using Paperclip."
    task :missing_styles => :environment do
      # Force loading all model classes to never miss any has_attached_file declaration:
      Dir[Rails.root + 'app/models/**/*.rb'].each { |path| load path }
      Paperclip.missing_attachments_styles.each do |klass, attachment_definitions|
        attachment_definitions.each do |attachment_name, missing_styles|
          puts "Regenerating #{klass} -> #{attachment_name} -> #{missing_styles.inspect}"
          ENV['CLASS'] = klass.to_s
          ENV['ATTACHMENT'] = attachment_name.to_s
          ENV['STYLES'] = missing_styles.join(',')
          Rake::Task['paperclip:refresh:thumbnails'].execute
        end
      end
      Paperclip.save_current_attachments_styles!
    end

    desc 'Regenerates width/height metadata for a given CLASS (and optional ATTACHMENT).'
    task :dimensions => :environment do
      klass = Paperclip::Task.obtain_class
      names = Paperclip::Task.obtain_attachments(klass)
      styles = ENV['STYLE'] || ENV['style']

      if styles
        styles = styles.split(',').map { |style| style.strip.to_sym }
      end

      names.each do |name|
        Paperclip.each_instance_with_attachment(klass, name) do |instance|
          attachment = instance.send(name)

          if styles.nil? || styles.empty?
            styles = instance.send(name).styles.map { |style| style[0] }

            styles << :original
          end

          styles.uniq!

          styles.each do |style|
            file = attachment.to_file(style)

            updated = false

            if file
              geometry = Paperclip::Geometry.from_file(file)

              instance.send("#{name}_#{style}_width=", geometry.width)
              instance.send("#{name}_#{style}_height=", geometry.height)

              updated = true
            else
              puts "Style \"#{style}\" does not exist!"
            end

            if updated
              instance.save(:validate => false)
            end
          end
        end
      end
    end

    desc 'Regenerates MD5 fingerprint for a given CLASS (and optional ATTACHMENT).'
    task :fingerprint => :environment do
      klass = Paperclip::Task.obtain_class
      names = Paperclip::Task.obtain_attachments(klass)

      names.each do |name|
        Paperclip.each_instance_with_attachment(klass, name) do |instance|

          if file = instance.send(name).to_file(:original)
            instance.send("#{name}_fingerprint=", Digest::MD5.hexdigest(file.read))

            instance.save(:validate => false)
          end
        end
      end
    end
  end

  desc "Cleans out invalid attachments. Useful after you've added new validations."
  task :clean => :environment do
    klass = Paperclip::Task.obtain_class
    names = Paperclip::Task.obtain_attachments(klass)
    names.each do |name|
      Paperclip.each_instance_with_attachment(klass, name) do |instance|
        unless instance.valid?
          attributes = %w(file_size file_name content_type).map{ |suffix| "#{name}_#{suffix}".to_sym }
          if attributes.any?{ |attribute| instance.errors[attribute].present? }
            instance.send("#{name}=", nil)
            if Rails.version >= "3.0.0"
              instance.save(:validate => false)
            else
              instance.save(false)
            end
          end
        end
      end
    end
  end
end