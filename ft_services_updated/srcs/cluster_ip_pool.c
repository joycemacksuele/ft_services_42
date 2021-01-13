/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   cluster_ip_pool.c                                  :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: jfreitas <jfreitas@student.s19.be>         +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2020/06/17 20:04:03 by jfreitas          #+#    #+#             */
/*   Updated: 2021/01/09 02:56:57 by jfreitas         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */
#include <stdio.h>

int		main(int argc, char **argv)
{
	char	cluster_ip_last_number;
	int		i;

	i = 11;
	if (argc == 2)
	{
		if (argv[1])
		{
			while (argv[1][i] != '\0')
				i++;
		}
	}
	i = i - 1;
	if (argv[1][i - 1] == '.')
	{
		if (argv[1][i] < '9')
			printf("%.11s%c", argv[1], argv[1][i] + 1);
		else if (argv[1][i] == '9')
			printf("%.11s%d", argv[1], 10);
	}
	if (argv[1][i - 2] == '.')
	{
		if (argv[1][i] < '9')
			printf("%.11s%c%c", argv[1], argv[1][i - 1], argv[1][i] + 1);
		else if (argv[1][i] == '9')
			printf("%.11s%c%d", argv[1], argv[1][i - 1] + 1, 0);
		else if (argv[1][i] == '9' && argv[1][i - 1] == '9')
			printf("%.11s%d", argv[1], 100);
	}
	if (argv[1][i - 3] == '.')
	{
		if (argv[1][i] < '9')
			printf("%.11s%c%c%c", argv[1], argv[1][i - 2], argv[1][i - 1],
			argv[1][i] + 1);
		else if (argv[1][i] == '9')
			printf("%.11s%c%c%d", argv[1], argv[1][i - 2],
			argv[1][i - 1] + 1, 0);
		else if (argv[1][i] == '9' && argv[1][i - 1] == '9')
			printf("%.11s%c%s", argv[1], argv[1][i - 2] + 1, "00");
	}
	return (0);
}
