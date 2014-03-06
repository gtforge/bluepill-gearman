require "bluepill-gearman/version"
require 'gearman'
require "bluepill"
require 'base64'
require "openssl"
require "digest"
 
module Bluepill
  module Gearman
    class SendGearman < Bluepill::Trigger
      <<-INFO
        Called by bluepill when a "checks :send_gearman" is declared in pill file
        @param [Bluepill::Process] process object from Bluepill see http://rdoc.info/github/arya/bluepill/master/Bluepill/Process
        @param [Hash] options available options:
          * gearman_server: the Gearman Server. mandatory
          * gearman_port: the gearman server port or default to 4730
          * host: the host defined in nagios to be hosting the service (default: hostname -f)
          * service: the service declared in nagios (default: the bluepill process name)
          * queue: default queue is 'check_results'
          * key: provide a key for encryption (minimum 8 bytes)
          * encryption: default to false set to true to enable
      
          See checks https://github.com/arya/bluepill for the syntax to pass those options
          encryption: https://gist.github.com/RiANOl/1077760
      INFO

      def initialize(process, options={})
        @default_args = {
          :gearman_job_server => ["#{options.delete(:gearman_server)}:#{options.delete(:gearman_port) || 4730}"],
          :host => options.delete(:host) || `hostname -f`.chomp,
          :service => options.delete(:service) || process.name,
          :queue => options.delete(:queue) || 'check_results',
          :key => options.delete(:key) || '',
          :encryption => options.delete(:encryption) || false
        }
        super
      end
      
      # Called by bluepill when process states changes. Notifies the nagios when:
      # * the process goes to :unmonitored notifies warning
      # * the process goes to :down notifies critical
      # * the process goes to :up notifies ok
      def notify(transition)
        _return_code, _status = case transition.to_name
        when :down
          [2, "Bluepill reported process down at #{Time.now}"]
        when :unmonitored
          [1 , "Bluepill stopped monitoring at #{Time.now}"]
        when :up
          [0 , "Running"]
        else
          [nil, nil]
        end
        if _status and _return_code
          _args = @default_args.merge({:status => _status, :return_code => _return_code})
          send_gearman(_args)
        end
      end

    protected
      def aes256_encrypt(key, data)
        key = null_padding(key)
        aes = OpenSSL::Cipher.new('AES-256-ECB')
        aes.encrypt
        aes.key = key
        aes.update(data) + aes.final
      end

      def null_padding(key)
        padding = (32 - key.bytesize) if(key.kind_of?(String) && 32 != key.bytesize)
        key += "\0" * padding
      end

      def send_gearman(args)
        begin
          client  = ::Gearman::Client.new(args[:gearman_job_server])
          job = <<-EOT
type=passive
host_name=#{args[:host]}
service_description=#{args[:service]}
start_time=#{Time.now.to_i}.0
finish_time=#{Time.now.to_i}.0
latency=0.0
return_code=#{args[:return_code]}
output=#{args[:status]}
EOT
          if args[:encryption]
            begin
              job = aes256_encrypt(args[:key], job)
            rescue Exception => e
              logger.warn "unable to encrypt: #{e}"
            end
          end
          encoded_job = Base64.encode64(job)
          result = client.do_task(args[:queue], encoded_job) 

          logger.info "Sent Job to Gearman Server #{result}"
        rescue Exception => e
          logger.warn "Failed to send job to the Gearman Server: #{e}"
        end
      end
    end
  end
end
