module Zimbra
  class Mailbox
		class << self
      def find_by_id(user_id)
        MailboxService.get_by_id(user_id)
			end
		end

		attr_accessor :id, :size

		def initialize(options = {})
			self.id = options[:id]
			self.size = options[:size]
    end
	end

  class MailboxService < HandsoapService
    def get_by_id(user_id)
      xml = invoke("n2:GetMailboxRequest") do |message|
				Builder.get_by_id(message, user_id)
			end
      Parser.mailbox_response(xml/"//n2:mbox")
    end

    class Builder
      class << self
        def get_by_id(message, user_id)
          message.add 'mbox', user_id do |c|
            c.set_attr 'id', user_id
          end
        end
      end
    end
    class Parser
      class << self
        def id_response(response)
          (response/"//n2:mbox").map do |node|
            mailbox_response(node)
          end
        end

        def mailbox_response(node)
          id = (node/'@mbxid').to_s
          size = (node/'@s').to_s
          Zimbra::Mailbox.new(:id => id, :size => size)
				end
			end
		end
	end
end
