class Comment < ApplicationRecord
  after_create :review_comment

  def review_comment
    ReviewCommentJob.perform_later(self)
  end
end
