NAME        = sorter
NAME2       = depthvis
CC          = gcc
CFLAGS      = -Wall -Wextra -g -std=c99 -D_REENTRANT
LDFLAGS     = $(shell sdl2-config --libs) -lm

SRCS        = main.c sorts.c bench.c
OBJS        = $(SRCS:.c=.o)

DEPTHVIS_SRCS = depthvis.c
DEPTHVIS_OBJS = $(DEPTHVIS_SRCS:.c=.o)

.PHONY: all clean fclean re

all: $(NAME) $(NAME2)

$(NAME): $(OBJS)
	$(CC) $(OBJS) -L. -ltciutil -ltci -o $(NAME)

$(NAME2): $(DEPTHVIS_OBJS)
	$(CC) $(DEPTHVIS_OBJS) -L. -ltci $(LDFLAGS) -o $(NAME2)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(DEPTHVIS_OBJS)

fclean: clean
	rm -f $(NAME) $(NAME2)

re: fclean all
