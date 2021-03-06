class BillsController < ApplicationController
  before_action :set_bill, only: [:show, :edit, :update, :destroy]

  # GET /bills
  # GET /bills.json
  def index
    @bills = if params[:term]
               Bill.all.search_by_text(params[:term])
             else
               Bill.order(open_states_updated_at: :desc).limit(5)
             end
    @bills_with_recent_activity = Bill.find(Vote.order(:created_at).pluck(:bill_id).uniq.last(15))
    authorize @bills
  end

  # GET /bills/1
  # GET /bills/1.json
  def show
    authorize @bill
  end

  # GET /bills/new
  def new
    authorize Bill
    @bill = Bill.new
  end

  # GET /bills/1/edit
  def edit
    authorize @bill
  end

  # POST /bills
  # POST /bills.json
  def create
    authorize Bill
    @bill = Bill.new(bill_params)

    respond_to do |format|
      if @bill.save
        format.html { redirect_to @bill, notice: 'Bill was successfully created.' }
        format.json { render :show, status: :created, location: @bill }
      else
        format.html { render :new }
        format.json { render json: @bill.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bills/1
  # PATCH/PUT /bills/1.json
  def update
    authorize @bill
    respond_to do |format|
      if @bill.update(bill_params)
        format.html { redirect_to @bill, notice: 'Bill was successfully updated.' }
        format.json { render :show, status: :ok, location: @bill }
      else
        format.html { render :edit }
        format.json { render json: @bill.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bills/1
  # DELETE /bills/1.json
  def destroy
    authorize @bill
    @bill.destroy
    respond_to do |format|
      format.html { redirect_to bills_url, notice: 'Bill was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def vote
    authorize Bill
    if @vote = Vote.find_by_user_id_and_bill_id(current_user.id, params[:bill_id])
      @vote.update(points: params[:points])
    else
      @vote = Vote.new(user_id: current_user.id,
                       bill_id: params[:bill_id],
                       points: params[:points])
    end
    respond_to do |format|
      if @vote.save
        format.html { redirect_to @vote.bill, flash: { success: 'Your vote has been recorded.' } }
        format.json { render :show, status: :created, location: @vote }
      else
        format.html { redirect_back fallback_location: root_path, warning: 'Sorry, there was an error.' }
        format.json { render json: @vote.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bill
      @bill = if params[:bill_id]
                Bill.find(params[:bill_id])
              else
                Bill.find_by_session_number(params[:id])
              end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def bill_params
      params.require(:bill).permit(:bill_id, :openstate_id, :title, :data)
    end
end
