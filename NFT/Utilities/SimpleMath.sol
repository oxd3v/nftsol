//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library SimpleMath {
    /**greater Number function for solidity
     * @dev cost 23803 gas for minimum array of 2 digit
     * @dev cost 990 amount of gas for per negative sign number concat to array of Numbers
     * @dev cost 622 amount of gas for each of the positive digit concat to array of numbers
     * @dev can get Max Number form Array of Numbers
     * @param numbers (int[]) array to find out greater one from these
     * @return greaterNumber from array of numbers
     */

    function GreaterNumber(int[] memory numbers) internal pure returns (int) {
        require(numbers.length > 0); // throw an exception if the condition is not met
        int greaterNumber; // default 0, the lowest value of `uint256`
        for (uint i = 0; i < numbers.length; i++) {
            if (numbers[i] > greaterNumber) {
                greaterNumber = numbers[i];
            }
        }
        return greaterNumber;
    }

    /** maxNumber function for uint[] solidity
     * @dev cost 23803 gas for minimum array of 2 digit
     * @dev cost 990 amount of gas for per negative sign number concat to array of Numbers
     * @dev cost 622 amount of gas for each of the positive digit concat to array of numbers
     * @dev can get Max Number form Array of Numbers
     * @param numbers (uint[])array to find out greater one from these
     * @return greaterNumber from array of numbers
     */

    function maxNumber(uint[] memory numbers) internal pure returns (uint) {
        require(numbers.length > 0); // throw an exception if the condition is not met
        uint greaterNumber; // default 0, the lowest value of `uint256`
        for (uint i = 0; i < numbers.length; i++) {
            if (numbers[i] > greaterNumber) {
                greaterNumber = numbers[i];
            }
        }
        return greaterNumber;
    }

    /** SmallerNumber function int[] array for solidity
     * @dev cost 24108 gas for minimum array of 2 digit
     * @dev cost 1332 amount of gas for per negative sign number concat to array of Numbers
     * @dev cost 896 amount of gas for each of the positive digit concat to array of numbers
     * @dev can get min(smaller) Number form Array of Numbers
     * @param numbers (int[])array to find out smaller one from these
     * @return smallerNumber from array of numbers
     */

    function SmallerNumber(int[] calldata numbers) external pure returns (int) {
        require(numbers.length > 0); // throw an exception if the condition is not met
        int greaterNumber; // default 0, the lowest value of `int`
        int differece;
        int smallerNumber;

        for (uint i = 0; i < numbers.length; i++) {
            if (numbers[i] > greaterNumber) {
                greaterNumber = numbers[i];
            }
        }

        for (uint i = 0; i < numbers.length; i++) {
            int diff = greaterNumber - numbers[i];
            if (diff > differece) {
                differece = diff;
                smallerNumber = numbers[i];
            }
        }
        return smallerNumber;
    }

    /** minNumber function uint[]array input for solidity
     * @dev cost 24108 gas for minimum array of 2 digit
     * @dev cost 1332 amount of gas for per negative sign number concat to array of Numbers
     * @dev cost 896 amount of gas for each of the positive digit concat to array of numbers
     * @dev can get min(smaller) Number form Array of Numbers
     * @param numbers (uint[])array to find out smaller one from these
     * @return smallerNumber from array of numbers
     */

    function minNumber(uint[] calldata numbers) external pure returns (uint) {
        require(numbers.length > 0); // throw an exception if the condition is not met
        uint greaterNumber; // default 0, the lowest value of `int`
        uint differece;
        uint smallerNumber;

        for (uint i = 0; i < numbers.length; i++) {
            if (numbers[i] > greaterNumber) {
                greaterNumber = numbers[i];
            }
        }

        for (uint i = 0; i < numbers.length; i++) {
            uint diff = greaterNumber - numbers[i];
            if (diff > differece) {
                differece = diff;
                smallerNumber = numbers[i];
            }
        }
        return smallerNumber;
    }
}
