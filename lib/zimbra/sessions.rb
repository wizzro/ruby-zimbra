module Zimbra
  class Sessions
    class << self
      def all
        SessionsService.all
      end
			def type(type)
				SessionsService.type(type)
			end
		end

    attr_accessor :id, :name, :session_id, :creation, :last_access

    def initialize(options = {})
      self.id = options[:id]
      self.name = options[:name]
			self.session_id = options[:sid]
			self.creation = options[:creation]
			self.last_access = options[:last_access]
    end
	end

  class SessionsService < HandsoapService
		def all
      xml = invoke("n2:GetSessionsRequest")
      Parser.get_all_response(xml)
    end

    def type(type)
      xml = invoke("n2:GetSessionsRequest") do |message|
				Builder.type(message, type)
			end
      Parser.get_all_response(xml)
    end

    def limit_by_number(limit)
      xml = invoke("n2:GetSessionsRequest") do |message|
				Builder.limit(message, limit)
			end
      Parser.get_all_response(xml)
    end

    class Builder
      class << self

				def type(message, type)
					message.add 'type', type
				end

				def limit(message, limit)
					message.add 'limit', limit
				end

      end
    end
    class Parser
      class << self
        def get_all_response(response)
          (response/"//n2:s").map do |node|
            session_response(node)
          end
        end

        def session_response(node)
          id = (node/'@zid').to_s
          name = (node/'@name').to_s
					session_id = (node/'@sid').to_s
					creation = (node/'@cd').to_s
					last_access = (node/'@ld').to_s
          Zimbra::Sessions.new(:id => id, :name => name, :session_id => session_id, :creation => creation, :last_access => last_access)
        end
      end
    end
  end
end
