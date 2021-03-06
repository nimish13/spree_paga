require 'spec_helper'

describe Spree::PagaNotification do
  it { should validate_presence_of(:transaction_id)}
  it { should validate_presence_of(:amount)}
  it { should validate_uniqueness_of(:transaction_id)}


  describe 'update_transaction_status' do
    before do
      @paga_notification = Spree::PagaNotification.new
      @paga_notification.transaction_id = 1
      @paga_notification.amount = 100
      @paga_notification.save!
    end

    context 'when transaction not present' do

      it "transaction should not be successful" do
        Spree::PagaTransaction.where(:transaction_id => @paga_notification.transaction_id).first.should be_nil 
      end
    end

    context 'when transaction present' do
      before do
        @order = Spree::Order.create!
      end

      context 'when amount is valid' do
        before do
          @order.update_column(:total, 100)
          @paga_transaction = @order.paga_transactions.new({:transaction_id => 1}, :without_protection => true)
          @paga_transaction.stub(:update_payment_source).and_return(true)
          @paga_transaction.stub(:finalize_order).and_return(true)
          @paga_transaction.save!
        end

        it "should be successful" do
          @paga_transaction.reload.should be_success
        end

        it "should have same amount as notification" do
          @paga_transaction.reload.amount.should eq(@paga_notification.amount)
        end
      end

      context 'when amount is not valid' do
        before do
          @order.update_column(:total, 100)
          @paga_transaction = @order.paga_transactions.new({:transaction_id => 1}, :without_protection => true)
          @paga_transaction.stub(:update_payment_source).and_return(true)
          @paga_transaction.stub(:finalize_order).and_return(true)
          @paga_transaction.stub(:update_transaction_status).and_return(true)
          @paga_transaction.save(:validate => false)
          @paga_transaction.amount = 0
          @paga_transaction.save(:validate => false)
        end
        it "transaction should not be successful" do
          @paga_transaction.should_not be_success
        end
      end
    end
  end


  describe '.build_with_params' do
    it "should save attributes of notification" do
      notification = Spree::PagaNotification.save_with_params({:transaction_reference => "123", :amount => 100.0, :transaction_type => "paga", :transaction_datetime => Time.current, :transaction_id => "trans123"})
      notification.transaction_reference.should  eq("123")
      notification.transaction_id.should  eq("trans123")
      notification.amount.should  eq(100.0)
      notification.transaction_type.should  eq("paga")
    end
  end
end