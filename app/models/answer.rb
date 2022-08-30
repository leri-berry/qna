class Answer < ApplicationRecord
  include Votable
  include Commentable

  belongs_to :question, touch: true
  belongs_to :author, class_name: 'User', foreign_key: 'user_id'
  has_many :links, dependent: :destroy, as: :linkable
  has_many :votes, dependent: :destroy, as: :votable
  has_many :comments, dependent: :destroy, as: :commentable

  has_many_attached :files
  accepts_nested_attributes_for :links, reject_if: :all_blank

  validates :body, presence: true

  def mark_as_best
    question.update(best_answer_id: id)
    question.award&.update!(user: author)
  end

  after_create :send_notification

  private

  def send_notification
    NotificationsJob.perform_later(self)
  end
end
