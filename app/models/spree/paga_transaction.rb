class Spree::PagaTransaction < ActiveRecord::Base
  attr_accessible :amount, :status
  MINIMUM_AMT = 1
  PENDING      = 'Pending'
  SUCCESSFUL  = 'Successful'
  UNSUCCESSFUL = 'Unsuccessful'

  belongs_to :order
  belongs_to :user
  validates :amount, :numericality => { :greater_than_or_equal_to => MINIMUM_AMT }
  validates :transaction_id, :order, :presence => true, :if => lambda {|t| t.response_status? }
  validates :transaction_id, :uniqueness => true

  before_validation :assign_values, :on => :create
  before_save :check_transaction_status, :unless => lambda {|t| t.success? }

  def assign_values
    self.status = PENDING
  end

  def success?
    status == SUCCESSFUL
  end

  def pending?
    status == PENDING
  end

  def amount_valid?
    amount >= order.remaining_total
  end

  def transaction_currency
    order.currency
  end

  private

  def check_transaction_status
    paga_notification = Spree::PagaNotification.where(:transaction_id => self.transaction_id).first
    if paga_notification && amount_valid?
      self.status = SUCCESSFUL
      self.amount = paga_notification.amount
    end
    true
  end
end
