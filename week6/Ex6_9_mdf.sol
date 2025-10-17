// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Ex6_9_modifier {

    enum FoodProcess{
        order,
        takeAway,
        delivery,
        payment
    }
    FoodProcess public foodStatus;

    constructor(){
        foodStatus = FoodProcess.payment;
    }

    modifier processCheck(FoodProcess _status){
        require(foodStatus == _status);
        _;
    }

    function orderFood() public processCheck(FoodProcess.payment) {
        foodStatus = FoodProcess.order;
    }
    function takeAwayFood() public processCheck(FoodProcess.order) {
        foodStatus = FoodProcess.takeAway;
    }
    function deliveryFood() public processCheck(FoodProcess.takeAway) {
        foodStatus = FoodProcess.delivery;
    }
    function paymentFood() public processCheck(FoodProcess.delivery) {
        foodStatus = FoodProcess.payment;
    }
    
}

