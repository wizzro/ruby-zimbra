module Zimbra
  class MailQueue
    class << self
      def all(server)
        MailQueueService.get_all(server)
      end

      def find_by_id(id)
        AccountService.get_by_id(id)
      end

      def find_by_name(name)
        AccountService.get_by_name(name)
      end

      def create(options)
        account = new(options)
        AccountService.create(account) 
      end

      def acl_name
        'account'
      end
    end

    attr_accessor :id, :name, :password, :acls, :cos_id, :delegated_admin, :mail_host

    def initialize(options = {})
      self.id = options[:id]
      self.name = options[:name]
      self.password = options[:password]
      self.acls = options[:acls] || []
      self.cos_id = (options[:cos] ? options[:cos].id : options[:cos_id])
			self.mail_host = options[:mail_host]
      self.delegated_admin = options[:delegated_admin]
    end

    def delegated_admin=(val)
      @delegated_admin = Zimbra::Boolean.read(val) 
    end
    def delegated_admin?
      @delegated_admin
    end

    def save
      AccountService.modify(self)
    end

    def delete
      AccountService.delete(self)
    end
  end

  class MailQueueService < HandsoapService
    def get_all(server)
      xml = invoke("n2:GetMailQueueInfoRequest") do |message|
				Builder.get_all(message, server)
			end
      Parser.get_all_response(xml)
    end

    def create(account)
      xml = invoke("n2:CreateAccountRequest") do |message|
        Builder.create(message, account)
      end
      Parser.account_response(xml/"//n2:account")
    end

    def get_by_id(id)
      xml = invoke("n2:GetAccountRequest") do |message|
        Builder.get_by_id(message, id)
      end
      return nil if soap_fault_not_found?
      Parser.account_response(xml/"//n2:account")
    end

    def get_by_name(name)
      xml = invoke("n2:GetAccountRequest") do |message|
        Builder.get_by_name(message, name)
      end
      return nil if soap_fault_not_found?
      Parser.account_response(xml/"//n2:account")
    end

    def modify(account)
      xml = invoke("n2:ModifyAccountRequest") do |message|
        Builder.modify(message, account)
      end
      Parser.account_response(xml/'//n2:account')
    end 

    def delete(dist)
      xml = invoke("n2:DeleteAccountRequest") do |message|
        Builder.delete(message, dist.id)
      end
    end

    class Builder
      class << self
				def get_all(message, server)
					message.add 'server' do |c|
						c.set_attr 'name', server
					end
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
        def get_all_response(node)
					p node.document.methods
					p node.document
					back = Hash.new
					(node/"//n2:queue/@name").each do |q|
						puts q.to_s + ' = ' + (node/"//n2:queue[@name='#{q}']/@n").to_s
						back[q] = (node/"//n2:queue[@name='#{q}']/@n").to_s
					end
					back
        end

        def account_response(node)
          id = (node/'@id').to_s
          name = (node/'@name').to_s
          acls = Zimbra::ACL.read(node)
          cos_id = Zimbra::A.read(node, 'zimbraCOSId')
          delegated_admin = Zimbra::A.read(node, 'zimbraIsDelegatedAdminAccount')
          mail_host = Zimbra::A.read(node, 'zimbraMailHost')
          Zimbra::Account.new(:id => id, :name => name, :acls => acls, :cos_id => cos_id, :delegated_admin => delegated_admin, :mail_host => mail_host)
        end
      end
    end
  end
end
