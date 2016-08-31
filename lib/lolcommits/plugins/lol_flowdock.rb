# -*- encoding : utf-8 -*-
require 'rest_client'

module Lolcommits
  class LolFlowdock < Plugin
    ENDPOINT_URL = 'api.flowdock.com/flows/'
    RETRY_COUNT  = 2

    def self.name
      'flowdock'
    end

    def self.runner_order
      :postcapture
    end

    def configured?
      !configuration['access_token'].nil?
    end

    def configure
      print "Open the URL below and issue a token for your user (Personal API token):\n"
      print "https://flowdock.com/account/tokens\n"
      print "Enter the generated token below, then press enter: \n"
      code = STDIN.gets.to_s.strip
      print "Enter the machine name of the flow you want to post to from this repo (go to https://www.flowdock.com/account and click Flows, then click the flow, and get the machine name from the URL):\n"
      flow = STDIN.gets.to_s.strip
      print "Enter the name of the organization for this Flowdock account.\n"
      organization = STDIN.gets.to_s.strip

      {
        'access_token' => code,
        'flow' => flow,
        'organization' => organization
      }
    end

    def configure_options!
      options = super
      if options['enabled']
        config = configure
        options.merge!(config)
      end
      options
    end

    def run_postcapture
      return unless valid_configuration?

      retries = RETRY_COUNT
      begin

        endpoint = 'https://' + configuration['access_token'] + '@' + ENDPOINT_URL + configuration['organization'] + '/' + configuration['flow'] + '/messages'
        puts endpoint
        response = RestClient.post(
          endpoint,
          {
            :event        => "file",
            :content      => File.new(runner.main_image),
          },
        )
        debug response
      rescue => e
        retries -= 1
        retry if retries > 0
        puts "Posting to flowdock failed - #{e.message}"
        puts 'Try running config again:'
        puts "\tlolcommits --config --plugin flowdock"
      end
    end
  end
end
