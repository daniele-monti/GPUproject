# adapted from the example at https://makefiletutorial.com/

SHELL := /bin/bash

TARGET_EXEC := bitsort
TARGET_TEST := run_tests

BUILD_DIR := ./build
SRC_DIRS := ./src
TEST_DIRS := ./tests

MAIN_FILE_NAME := main.cu

CC := gcc
CXX := g++
NVCC := nvcc

# Find all the C and C++ files we want to compile
# Note the single quotes around the * expressions. The shell will incorrectly expand these otherwise, but we want to send the * directly to the find command.
SRCS := $(shell find $(SRC_DIRS) -name '*.cpp' -or -name '*.c' -or -name '*.cu')

TEST_SRCS := $(shell find $(TEST_DIRS) -name '*.cpp' -or -name '*.c' -or -name '*.cu')
TEST_SRCS += $(filter-out $(SRC_DIRS)/$(MAIN_FILE_NAME), $(SRCS))

# Prepends BUILD_DIR and appends .o to every src file
# As an example, ./src/hello.cpp turns into ./build/./src/hello.cpp.o
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)
TEST_OBJS := $(TEST_SRCS:%=$(BUILD_DIR)/%.o)

# String substitution (suffix version without %).
# As an example, ./build/hello.cpp.o turns into ./build/hello.cpp.d
DEPS := $(OBJS:.o=.d)
TEST_DEPS := $(TEST_OBJS:.o=.d)

# Every folder in ./src will need to be passed to GCC so that it can find header files
INC_DIRS := $(shell find $(SRC_DIRS) -type d)
# Add a prefix to INC_DIRS. So moduleA would become -ImoduleA. GCC understands this -I flag
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

# The -MMD and -MP flags together generate Makefiles for us!
# These files will have .d instead of .o as the output.
# see links below for a more thorough explanation
# https://make.mad-scientist.net/papers/advanced-auto-dependency-generation/
# https://www.cse.unr.edu/~sushil/class/cs202/help/man/make/make_42.html
CPPFLAGS := $(INC_FLAGS) -Wall -MMD -MP

# needed for linking different compilation units together
# https://docs.nvidia.com/cuda/cuda-programming-guide/02-basics/nvcc.html
NVCCLDFLAGS := -dlto
NVCCFLAGS := -dc -dlto $(INC_FLAGS) -MMD -MP

# The final build step.
$(BUILD_DIR)/$(TARGET_EXEC): $(OBJS)
	$(NVCC) $(NVCCLDFLAGS) $(OBJS) -o $@

# Build step for CU source
$(BUILD_DIR)/%.cu.o: %.cu
	mkdir -p $(dir $@)
	$(NVCC) $(NVCCFLAGS) $(CXXFLAGS) -c $< -o $@

# Build step for C source
$(BUILD_DIR)/%.c.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# Build step for C++ source
$(BUILD_DIR)/%.cpp.o: %.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@


.PHONY: test
test: $(TEST_OBJS)
	$(NVCC) $(NVCCLDFLAGS) $(TEST_OBJS) -o $(BUILD_DIR)/$(TARGET_TEST)
	$(BUILD_DIR)/$(TARGET_TEST)


.PHONY: clean
clean:
	rm -r $(BUILD_DIR)

# Include the .d makefiles. The - at the front suppresses the errors of missing
# Makefiles. Initially, all the .d files will be missing, and we don't want those
# errors to show up.
-include $(DEPS)
-include $(TEST_DEPS)
