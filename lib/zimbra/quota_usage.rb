module Zimbra
  class QuotaUsage
    class << self
      def all
        QuotaUsageService.all
      end

			def limit_by_number(limit)
				QuotaUsageService.limit_by_number(limit)
			end

			def domain(domain, sort)
				QuotaUsageService.domain(domain, sort)
			end

			def method_missing(method, *args, &block)
				if method.to_s =~ /^limit_by_(\d+)$/
					limit_by_number($1, *args, &block)
				else
					super
				end
			end
		end

		def all
			QuotaUsageService.all
		end

		def limit_by_number(limit)
			QuotaUsageService.limit_by_number(limit)
		end

		def method_missing(method, *args, &block)
			if method.to_s =~ /^limit_by_(\d+)$/
				limit_by_number($1, *args, &block)
			else
				super
			end
		end

    attr_accessor :id, :name, :used, :limit, :domain

    def initialize(options = {})
      self.id = options[:id]
      self.name = options[:name]
      self.used = options[:used]
      self.limit = options[:limit]
      self.domain = options[:domain]
    end
	end

  class QuotaUsageService < HandsoapService
		def all
      xml = invoke("n2:GetQuotaUsageRequest")
      Parser.get_all_response(xml)
    end

    def limit_by_number(limit)
      xml = invoke("n2:GetQuotaUsageRequest") do |message|
				Builder.limit(message, limit)
			end
      Parser.get_all_response(xml)
    end

    def domain(domain, sort)
      xml = invoke("n2:GetQuotaUsageRequest") do |message|
				Builder.domain(message, domain, sort)
			end
      Parser.get_all_response(xml)
    end

    def get_by_name(name)
      xml = invoke("n2:GetAccountRequest") do |message|
        Builder.get_by_name(message, name)
      end
      return nil if soap_fault_not_found?
      Parser.account_response(xml/"//n2:account")
    end

    class Builder
      class << self

				def limit(message, limit)
					message.add 'limit', limit
				end

				def domain(message, domain, sort)
					message.add 'domain', domain
					message.add 'sort', sort
					message.add 'limit', "20"
				end

        def create(message, account)
          message.add 'name', account.name
          message.add 'password', account.password
          A.inject(message, 'zimbraCOSId', account.cos_id)
        end
        
        def get_by_id(message, id)
          message.add 'account', id do |c|
            c.set_attr 'by', 'id'
          end
        end

        def get_by_name(message, name)
          message.add 'account', name do |c|
            c.set_attr 'by', 'name'
          end
        end

        def modify(message, account)
          message.add 'id', account.id
          modify_attributes(message, distribution_list)
        end
        def modify_attributes(message, account)
          if account.acls.empty?
            ACL.delete_all(message)
          else
            account.acls.each do |acl|
              acl.apply(message)
            end
          end
          Zimbra::A.inject(node, 'zimbraCOSId', account.cos_id)
          Zimbra::A.inject(node, 'zimbraIsDelegatedAdminAccount', (delegated_admin ? 'TRUE' : 'FALSE'))
        end

        def delete(message, id)
          message.add 'id', id
        end
      end
    end
    class Parser
      class << self
        def get_all_response(response)
          (response/"//n2:account").map do |node|
            account_response(node)
          end
        end

        def account_response(node)
          id = (node/'@id').to_s
          name = (node/'@name').to_s
          used = (node/'@used').to_s
          limit = (node/'@limit').to_s
          domain = (node/'@domain').to_s
          Zimbra::QuotaUsage.new(:id => id, :name => name, :used => used, :limit => limit, :domain => domain)
        end
      end
    end
  end
end
