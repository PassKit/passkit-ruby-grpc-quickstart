require_relative "../workflow"

module PassKit
  class CouponWorkflow < Workflow
    def execute
      template_id = create_template(:SINGLE_USE_COUPON, "Ruby Quickstart Coupon")
      vip_template_id = create_template(:SINGLE_USE_COUPON, "Ruby Quickstart VIP Coupon")
      campaign_id = id(rpc(:coupons, :create_coupon_campaign, SingleUseCoupons::CouponCampaign.new(
                                                                name: "Ruby Coupons #{SecureRandom.hex(3)}", status: %i[
                                                                  PROJECT_DRAFT PROJECT_ACTIVE_FOR_OBJECT_CREATION
                                                                ]
                                                              )))
      remember("campaign", campaign_id) { |value| rpc(:coupons, :delete_coupon_campaign, Io::Id.new(id: value)) }
      now = Google::Protobuf::Timestamp.new(seconds: Time.now.to_i)
      tomorrow = Google::Protobuf::Timestamp.new(seconds: (Time.now + 86_400).to_i)
      offer_id = id(rpc(:coupons, :create_coupon_offer, SingleUseCoupons::CouponOffer.new(
                                                          id: "base", campaignId: campaign_id,
                                                          offerTitle: "Ruby Quickstart Offer", offerShortTitle: "Ruby Offer",
                                                          offerDetails: "Your Ruby quickstart offer",
                                                          beforeRedeemPassTemplateId: template_id, issueStartDate: now,
                                                          issueEndDate: tomorrow, ianaTimezone: "Europe/London"
                                                        )))
      vip_offer_id = id(rpc(:coupons, :create_coupon_offer, SingleUseCoupons::CouponOffer.new(
                                                              id: "vip", campaignId: campaign_id,
                                                              offerTitle: "Ruby VIP Offer", offerShortTitle: "VIP",
                                                              offerDetails: "Your Ruby quickstart VIP offer",
                                                              beforeRedeemPassTemplateId: vip_template_id, issueStartDate: now,
                                                              issueEndDate: tomorrow, ianaTimezone: "Europe/London"
                                                            )))
      coupon_id = id(rpc(:coupons, :create_coupon, SingleUseCoupons::Coupon.new(
                                                     campaignId: campaign_id, offerId: offer_id, person: person("Ruby Coupon Holder")
                                                   )))
      rpc(:coupons, :get_coupon_by_id, Io::Id.new(id: coupon_id))
      rpc(:coupons, :list_coupons_by_coupon_campaign,
          SingleUseCoupons::ListRequest.new(couponCampaignId: campaign_id)).to_a
      rpc(:coupons, :count_coupons_by_coupon_campaign,
          SingleUseCoupons::ListRequest.new(couponCampaignId: campaign_id))
      rpc(:coupons, :update_coupon, SingleUseCoupons::Coupon.new(
                                      id: coupon_id, campaignId: campaign_id, offerId: offer_id,
                                      person: person("Updated Ruby Coupon Holder")
                                    ))
      rpc(:coupons, :redeem_coupon, SingleUseCoupons::Coupon.new(id: coupon_id, campaignId: campaign_id))
      second_id = id(rpc(:coupons, :create_coupon, SingleUseCoupons::Coupon.new(
                                                     campaignId: campaign_id, offerId: vip_offer_id,
                                                     person: person("Ruby Void Coupon")
                                                   )))
      rpc(:coupons, :void_coupon, SingleUseCoupons::Coupon.new(id: second_id, campaignId: campaign_id))
      puts "Created coupon pass: #{coupon_id}"
    end
  end
end
