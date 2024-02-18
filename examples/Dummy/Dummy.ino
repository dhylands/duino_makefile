/****************************************************************************
 *
 *   @copyright Copyright (c) 2024 Dave Hylands     <dhylands@gmail.com>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the MIT License version as described in the
 *   LICENSE file in the root of this repository.
 *
 ****************************************************************************/

#include <Arduino.h>

void setup() {
    Serial.begin();
}

static uint32_t counter = 0;

void loop() {
    Serial.printf("Counter = %" PRIu32 "\r\n", counter);
    delay(1000);
    counter++;
}
