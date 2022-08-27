class Services::Notifications
  def initialize(answer)
    @answer = answer
  end

  def send_notification
    @question = @answer.question
    @question.subscriptions.find_each do |subscription|
      NotificationsMailer.notification(subscription.user, @answer).deliver_later
    end
  end
end