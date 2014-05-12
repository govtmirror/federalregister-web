namespace :mailing_lists do
  namespace :articles do
    desc "Deliver the document mailing list content for a given day"
    task :deliver, [:date] => :environment do |t, args|
      date = Date.parse(args[:date])
      
      MailingList::Article.active.find_each do |mailing_list|
        begin
          mailing_list.deliver!(date, :force_delivery => ENV['FORCE_DELIVERY'])
        rescue Exception => e
          Rails.logger.warn(e)
          Honeybadger.notify(e, :context => {:mailing_list_id => mailing_list.id})
        end
      end
    end
  end

  namespace :public_inspection do
    desc "Deliver the PI mailing list content for the specified documents"
    task :deliver, [:document_numbers] => :environment do |t, args|
      new_document_numbers = args[:document_numbers].split(/;/)

      MailingList::PublicInspectionDocument.active.find_each do |mailing_list|
        begin
          mailing_list.deliver!(new_document_numbers)
        rescue Exception => e
          Rails.logger.warn(e)
          Honeybadger.notify(e, :context => {:mailing_list_id => mailing_list.id})
        end
      end
    end
  end

  desc "recalculate active subscriptions for this environment"
  task :recalculate_counts => :environment do
    MailingList.connection.execute("UPDATE mailing_lists SET active_subscriptions_count = 0")
    MailingList.connection.execute("UPDATE mailing_lists,
          (
           SELECT mailing_list_id, COUNT(subscriptions.id) AS count
           FROM subscriptions
           WHERE subscriptions.environment = '#{Rails.env}'
             AND subscriptions.confirmed_at IS NOT NULL
             AND subscriptions.unsubscribed_at IS NULL
           GROUP BY subscriptions.mailing_list_id
          ) AS subscription_counts
       SET mailing_lists.active_subscriptions_count = subscription_counts.count
       WHERE mailing_lists.id = subscription_counts.mailing_list_id")
  end
end
