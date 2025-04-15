class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { player: 0, admin: 1 }


  def impersonated_by
    Thread.current[:impersonator]
  end
end
