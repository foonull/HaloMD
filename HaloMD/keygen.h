// Header for keygen.c

#ifndef KEYGEN_H
#define KEYGEN_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

void generate_key(uint8_t *key);
void fix_key(uint8_t *key);
void print_key(char *dst, const uint8_t *key);

#endif
